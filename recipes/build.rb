# TODO: pull this up higher
include_recipe "git"

app_name = node['app_name']

# Encapsulate the logic for stopping the app service, rebuilding the
# app, and restarting the service (at the end of the Chef run)
ruby_block "rebuild_#{app_name}" do
  block do
    Chef::Log.info("Stopping #{app_name} service (if it exists) and rebuilding")
  end
  if File.directory?("#{node['runit']['sv_dir']}/#{app_name}")
    notifies :stop, "service[#{app_name}]", :immediately
  end

  if node[app_name]['development_mode']
    # Don't fetch deps again, just rebuild the release; if you add
    # another dep, either manually call 'rebar get-deps', or just
    # rebuild the VM
    notifies :run, "execute[rel_#{app_name}]", :immediately
  else
    notifies :run, "execute[distclean_#{app_name}]", :immediately
  end

  notifies :restart, "service[#{app_name}]", :delayed
  action :nothing
end

# Fetch the code for the application from the Git repository.  If
# running in development mode, we assume the code is already present
# (e.g., is in /vagrant) and bypass the code retrieval
if node[app_name]['development_mode']
  # Not fetching code, but we do need to send the appropriate signals
  # to stop the service and rebuild it, though

  ruby_block "signal_rebuild" do
    block do
      Chef::Log.info("Signalling a rebuild in development mode")
    end
    notifies :create, "ruby_block[rebuild_#{app_name}]", :immediately
  end
else
  # Grab the source
  git app_name do
    destination node[app_name]['src_dir']
    repository "git@github.com:opscode/#{app_name}.git"
    revision node[app_name]['revision']
    user "opscode"
    group "opscode"
    notifies :create, "ruby_block[rebuild_#{app_name}]", :immediately
  end
end

execute "distclean_#{app_name}" do
  # erlexec needs HOME env var to be set. If it's not set, it errors out.
  # This seems to happen when chef-client runs daemonized.
  unless ENV['HOME']
    Chef::Log.info("HOME is not set. Setting to /root.")
    environment({'HOME' => '/root'})
  end

  command "make distclean"
  cwd node[app_name]['src_dir']
  notifies :run, "execute[rel_#{app_name}]", :immediately
  action :nothing
end

execute "rel_#{app_name}" do
  # erlexec needs HOME env var to be set. If it's not set, it errors out.
  # This seems to happen when chef-client runs daemonized.
  unless ENV['HOME']
    Chef::Log.info("HOME is not set. Setting to /root.")
    environment({'HOME' => '/root'})
  end

  command "make relclean rel"
  cwd node[app_name]['src_dir']
  action :nothing
end

if node[app_name]['development_mode']
  # TODO: I don't really like this
  #
  # This is to ensure that we can "link" our 'etc' configuration
  # directory into the release directory.  When we're in development
  # mode, this directory is on the /vagrant filesystem, and we
  # apparently can't make links into it.  As a work around, we'll just
  # copy the final release into the appropriate place.
  execute "rm -Rf #{node[app_name]['srv_dir']}" do
    only_if "test -d #{node[app_name]['srv_dir']}"
  end
  execute "cp -R #{node[app_name]['rel_dir']} #{File.dirname(node[app_name]['srv_dir'])}"
  execute "chown -R opscode:opscode #{node[app_name]['srv_dir']}"
else
  # Otherwise, we just link things up and we're done with it.
  link "link_release_to_service_directory" do
    to node[app_name]['rel_dir']
    target_file node[app_name]['srv_dir']
    owner "opscode"
    group "opscode"
  end
end

link "link_etc_dir_into_srv_dir" do
  to node[app_name]['etc_dir']
  target_file "#{node[app_name]['srv_dir']}/etc"
  owner "opscode"
  group "opscode"
end

directory node[app_name]['bin_dir'] do
  owner "opscode"
  group "opscode"
  mode "0755"
end


# TODO: use common structure for this.. this is currently the ONLY
# PLACE in this recipe that refers to 'oc_bifrost' specifically

vips = data_bag_item("vips", node[:app_environment])

if node['stats_hero'] && node['stats_hero']['estatsd_host']
  estatsd_host = node['stats_hero']['estatsd_host']
else
  estatsd_host = vips['estatsd_host']
end

# DB host is 1) node override or 2) VIP or 3) role query
db_host = if node[app_name]['database']['host']
  Chef::Log.info("Using node attribute for #{app_name} DB host")
  node[app_name]['database']['host']
elsif vips["bifrost_pgsql_ip"]
  Chef::Log.info("Using VIP for #{app_name} DB host")
  vips["bifrost_pgsql_ip"]
else
  Chef::Log.info("Using role for #{app_name} DB host")
  search(:node, "role:bifrost-pgsql")[0].ipaddress
end

# superuser ID is in the environments databag
env = data_bag_item("environments", node[:app_environment])
superuser_id = env['auth-superuser-id']

config_variables = {
  :ip                   => node['oc_bifrost']['host'],
  :port                 => node['oc_bifrost']['port'],
  :superuser_id         => superuser_id,
  :console_log_size     => node['oc_bifrost']['console_log_size'],
  :console_log_count    => node['oc_bifrost']['console_log_count'],
  :error_log_size       => node['oc_bifrost']['error_log_size'],
  :error_log_count      => node['oc_bifrost']['error_log_count'],
  :db_host              => db_host,
  :db_port              => node['oc_bifrost']['database']['port'],
  :db_name              => node['oc_bifrost']['database']['name'],
  :db_user              => node['oc_bifrost']['database']['users']['owner']['name'],
  :db_pass              => node['oc_bifrost']['database']['users']['owner']['password'],
  :pool_size            => node['oc_bifrost']['database']['connection_pool_size'],
  :max_pool_size        => node['oc_bifrost']['database']['max_connection_pool_size'],
  :log_dir              => node['oc_bifrost']['log_dir'],
  :udp_socket_pool_size => node['oc_bifrost']['stats_hero_udp_socket_pool_size'],

  # TODO: need to get this from search?
  :estatsd_host => estatsd_host,
  :estatsd_port => node['stats_hero']['estatsd_port']
}

template "#{node[app_name]['etc_dir']}/sys.config" do
  owner "opscode"
  group "opscode"
  mode 0644
  variables(config_variables)
  notifies :restart, "service[#{app_name}]", :delayed
end

template "#{node[app_name]['etc_dir']}/vm.args" do
  owner "opscode"
  group "opscode"
  mode 0644
  variables(:app_name => app_name)
  notifies :restart, "service[#{app_name}]", :delayed
end

# This is the script that will actually run the application.  It is
# enhanced from the standard Erlang release boot script in that it has
# support for running under runit.
template "#{node[app_name]['bin_dir']}/#{app_name}" do
  source "run_script.sh.erb"
  owner "opscode"
  group "opscode"
  mode 0755
  variables(:log_dir => node[app_name]['log_dir'])
  notifies :restart, "service[#{app_name}]", :delayed
end

# These are some stock scripts that the boot script needs to call.
["nodetool", "erl"].each do |file|
  cookbook_file "#{node[app_name]['bin_dir']}/#{file}" do
    owner "opscode"
    group "opscode"
    mode 0755
  end
end

# Drop off an rsyslog configuration
template "/etc/rsyslog.d/30-#{app_name}.conf" do
  source "erlang_app_rsyslog.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(:app_name => app_name,
            :log_file_path => "/var/log/#{app_name}.log")
  notifies :restart, "service[rsyslog]"
end
