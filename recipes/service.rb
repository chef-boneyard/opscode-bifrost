app_name = node['app_name']

# Remove the baked-in etc directory from the oc_bifrost release
# process.  This was added in version 1.1.5 to make bundling
# oc_bifrost into OPC builds a little easier; that build process does
# not currently use this cookbook (sadly), and so some of the files
# laid down for the release in this cookbook (etc/vm.args,
# bin/nodetool, bin/erl, bin/oc_bifrost) are now also baked into the
# release process.  The sys.config is still templatized in OPC, of
# course.
#
# Long story short, we need to nuke the etc directory that is
# created by the OTP release process before linking it in from the
# "real" place the etc files from this cookbook come from.
#
# Harmonizing OPC and OHC cookbooks can't come quickly enough!
directory "#{node[app_name]['srv_dir']}/etc" do
  action :delete
  recursive true
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

config_variables = {
  :ip                   => node['oc_bifrost']['host'],
  :port                 => node['oc_bifrost']['port'],
  :superuser_id         => node['oc_bifrost']['superuser_id'],
  :db_host              => node['oc_bifrost']['database']['host'],
  :db_port              => node['oc_bifrost']['database']['port'],
  :db_name              => node['oc_bifrost']['database']['name'],
  :db_user              => node['oc_bifrost']['database']['users']['owner']['name'],
  :db_pass              => node['oc_bifrost']['database']['users']['owner']['password'],
  :pool_size            => node['oc_bifrost']['database']['connection_pool_size'],
  :max_pool_size        => node['oc_bifrost']['database']['max_connection_pool_size'],
  :log_dir              => node['oc_bifrost']['log_dir'],
  :udp_socket_pool_size => node['oc_bifrost']['stats_hero_udp_socket_pool_size'],

  # TODO: need to get this from search?
  :estatsd_host => node['oc_bifrost']['estatsd_host'],
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

# Use logrotate for, um, log rotation
template "/etc/logrotate.d/#{app_name}" do
  source 'logrotate.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
              :console_log_count => node['oc_bifrost']['log_rotation']['console_log']['num_to_keep'],
              :console_log_size  => node['oc_bifrost']['log_rotation']['console_log']['file_maxbytes'],
              :error_log_count   => node['oc_bifrost']['log_rotation']['error_log']['num_to_keep'],
              :error_log_size    => node['oc_bifrost']['log_rotation']['error_log']['file_maxbytes'],
              :log_dir           => node['oc_bifrost']['log_dir']
            })
end

# Bifrost is chatty, so we'll want to be a bit more aggressive running
# logrotate to ensure that log sizes don't get too big.
template "/etc/cron.hourly/logrotate" do
  cookbook "logrotate"
  owner "root"
  group "root"
  mode "644"
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
