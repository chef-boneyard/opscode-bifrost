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

runit_service 'oc_bifrost' do
  template_name "erlang_app" # Our common template
  options({
            :srv_dir => node['oc_bifrost']['srv_dir'],
            :bin_name => 'oc_bifrost',

            # See http://smarden.org/runit/chpst.8.html

            # These are for the run script
            :run_setuidgid => "opscode",
            :run_envuidgid => "opscode",

            # This is for the log-run script
            :log_setuidgid => "nobody"
          })
  if File.directory?("#{node['runit']['sv_dir']}/oc_bifrost")
    subscribes :stop, "ruby_block[rebuild_oc_bifrost]", :immediately
  end
  subscribes :restart, "ruby_block[rebuild_oc_bifrost]", :delayed
end
