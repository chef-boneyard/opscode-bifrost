app_name = node['app_name']

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
superuser_id = env['opscode-authz-superuser-id']

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


include_recipe "runit"
runit_service app_name do
  template_name "erlang_app" # Our common template
  options({
            :srv_dir => node[app_name]['srv_dir'],
            :bin_name => app_name,
            :app_name => app_name,

            # See http://smarden.org/runit/chpst.8.html

            # These are for the run script
            :run_setuidgid => "opscode",
            :run_envuidgid => "opscode",

            # This is for the log-run script
            :log_setuidgid => "nobody"
          })
end
