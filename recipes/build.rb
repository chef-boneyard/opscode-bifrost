# Encapsulate the logic for stopping the app service, rebuilding the
# app, and restarting the service (at the end of the Chef run)
ruby_block "rebuild_oc_bifrost" do
  block do
    Chef::Log.info("Stopping oc_bifrost service (if it exists) and rebuilding")
  end
  if File.directory?("#{node['runit']['sv_dir']}/oc_bifrost")
    notifies :stop, "service[oc_bifrost]", :immediately
  end

  if node['oc_bifrost']['development_mode']
    # Don't fetch deps again, just rebuild the release; if you add
    # another dep, either manually call 'rebar get-deps', or just
    # rebuild the VM
    notifies :run, "execute[rel_oc_bifrost]", :immediately
  else
    notifies :run, "execute[distclean_oc_bifrost]", :immediately
  end

  notifies :restart, "service[oc_bifrost]", :delayed
  action :nothing
end

# Fetch the code for the application from the Git repository.  If
# running in development mode, we assume the code is already present
# (e.g., is in /vagrant) and bypass the code retrieval
if node['oc_bifrost']['development_mode']
  # Not fetching code, but we do need to send the appropriate signals
  # to stop the service and rebuild it, though

  ruby_block "signal_rebuild" do
    block do
      Chef::Log.info("Signalling a rebuild in development mode")
    end
    notifies :create, "ruby_block[rebuild_oc_bifrost]", :immediately
  end
else
  # Grab the source
  git 'oc_bifrost' do
    destination node['oc_bifrost']['src_dir']
    repository "git@github.com:opscode/oc_bifrost.git"
    revision node['oc_bifrost']['revision']
    user "opscode"
    group "opscode"
    notifies :create, "ruby_block[rebuild_oc_bifrost]", :immediately
  end
end

execute "distclean_oc_bifrost" do
  command "make distclean"
  cwd node['oc_bifrost']['src_dir']
  notifies :run, "execute[rel_oc_bifrost]", :immediately
  action :nothing
end

execute "rel_oc_bifrost" do
  command "make relclean rel"
  cwd node['oc_bifrost']['src_dir']
  action :nothing
end

if node['oc_bifrost']['development_mode']
  # TODO: I don't really like this
  #
  # This is to ensure that we can "link" our 'etc' configuration
  # directory into the release directory.  When we're in development
  # mode, this directory is on the /vagrant filesystem, and we
  # apparently can't make links into it.  As a work around, we'll just
  # copy the final release into the appropriate place.
  execute "rm -Rf #{node['oc_bifrost']['srv_dir']}" do
    only_if "test -d #{node['oc_bifrost']['srv_dir']}"
  end
  execute "cp -R #{node['oc_bifrost']['rel_dir']} #{File.dirname(node['oc_bifrost']['srv_dir'])}"
  execute "chown -R opscode:opscode #{node['oc_bifrost']['srv_dir']}"
else
  # Otherwise, we just link things up and we're done with it.
  link "link_release_to_service_directory" do
    to node['oc_bifrost']['rel_dir']
    target_file node['oc_bifrost']['srv_dir']
    owner "opscode"
    group "opscode"
  end
end

link "link_etc_dir_into_srv_dir" do
  to node['oc_bifrost']['etc_dir']
  target_file "#{node['oc_bifrost']['srv_dir']}/etc"
  owner "opscode"
  group "opscode"
end

directory node['oc_bifrost']['bin_dir'] do
  owner "opscode"
  group "opscode"
  mode "0755"
end


# TODO: use common structure for this.. this is currently the ONLY
# PLACE in this recipe that refers to 'oc_bifrost' specifically

if node['stats_hero'] && node['stats_hero']['estatsd_host']
  estatsd_host = node['stats_hero']['estatsd_host']
else
  estatsd_host = data_bag_item("vips", node[:app_environment])['estatsd_host']
end

config_variables = {
  :ip        => node['oc_bifrost']['host'],
  :port      => node['oc_bifrost']['port'],
  :db_host   => node['oc_bifrost']['database']['host'] || search(:node, "role:authz-pgsql")[0].ipaddress,
  :db_port   => node['oc_bifrost']['database']['port'],
  :db_name   => node['oc_bifrost']['database']['name'],
  :db_user   => node['oc_bifrost']['database']['users']['owner']['name'],
  :db_pass   => node['oc_bifrost']['database']['users']['owner']['password'],
  :pool_size => node['oc_bifrost']['database']['connection_pool_size'],
  :max_pool_size => node['oc_bifrost']['database']['max_connection_pool_size'],
  :log_dir   => node['oc_bifrost']['log_dir'],
  :udp_socket_pool_size => node['oc_bifrost']['stats_hero_udp_socket_pool_size'],

  # TODO: need to get this from search?
  :estatsd_host => estatsd_host,
  :estatsd_port => node['stats_hero']['estatsd_port']
}

template "#{node['oc_bifrost']['etc_dir']}/sys.config" do
  owner "opscode"
  group "opscode"
  mode 0644
  variables(config_variables)
  notifies :restart, "service[oc_bifrost]", :delayed
end

template "#{node['oc_bifrost']['etc_dir']}/vm.args" do
  owner "opscode"
  group "opscode"
  mode 0644
  notifies :restart, "service[oc_bifrost]", :delayed
end

# This is the script that will actually run the application.  It is
# enhanced from the standard Erlang release boot script in that it has
# support for running under runit.
template "#{node['oc_bifrost']['bin_dir']}/oc_bifrost" do
  source "run_script.sh.erb"
  owner "opscode"
  group "opscode"
  mode 0755
  variables(:log_dir => node['oc_bifrost']['log_dir'])
  notifies :restart, "service[oc_bifrost]", :delayed
end

# These are some stock scripts that the boot script needs to call.
["nodetool", "erl"].each do |file|
  cookbook_file "#{node['oc_bifrost']['bin_dir']}/#{file}" do
    owner "opscode"
    group "opscode"
    mode 0755
  end
end

# Drop off an rsyslog configuration
template "/etc/rsyslog.d/30-oc_bifrost.conf" do
  source "erlang_app_rsyslog.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(:log_file_path => "/var/log/oc_bifrost.log")
  notifies :restart, "service[rsyslog]"
end
