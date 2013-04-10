#
# Set up private chef vs. hosted chef config
#
if node['private_chef']
  bifrost_config = node['private_chef']['oc_bifrost']
  service_owner = node['private_chef']['user']['username']
  service_group = node['private_chef']['user']['username']
  estatsd_host = node['private_chef']['estatsd']['vip']
  estatsd_port = node['private_chef']['estatsd']['port']
  db_host = node['private_chef']['postgresql']['vip']
  db_port = 5432
else
  bifrost_config = node['oc_bifrost']
  service_owner = 'opscode'
  service_group = 'opscode'

  # TODO: need to get this from search?
  if node['stats_hero'] && node['stats_hero']['estatsd_host']
    estatsd_host = node['stats_hero']['estatsd_host']
  else
    estatsd_host = data_bag_item("vips", node[:app_environment])['estatsd_host']
  end
  estatsd_port = node['stats_hero']['estatsd_port']

  db_host = node['oc_bifrost']['database']['host'] || search(:node, "role:authz-pgsql")[0].ipaddress
  db_port = node['oc_bifrost']['database']['port']
end

service_dir = bifrost_config['srv_dir']
log_dir = bifrost_config['log_dir']

#
# Ensure service directories exist
#
[ service_dir, "#{service_dir}/etc", log_dir, "#{log_dir}/sasl" ].each do |dir_name|
  directory dir_name do
    owner service_owner
    group service_group
    mode '0700'
    recursive true
  end
end

link "#{service_dir}/log" do
  to log_dir
  owner service_owner
  group service_group
end

directory "#{service_dir}/bin" do
  owner service_owner
  group service_group
  mode "0755"
end

#
# Set up scripts and configuration
#
config_variables = {
  :ip        => bifrost_config['host'],
  :port      => bifrost_config['port'],
  :db_host   => db_host,
  :db_port   => db_port,
  :db_name   => bifrost_config['database']['name'],
  :db_user   => bifrost_config['database']['users']['owner']['name'],
  :db_pass   => bifrost_config['database']['users']['owner']['password'],
  :pool_size => bifrost_config['database']['connection_pool_size'],
  :max_pool_size => bifrost_config['database']['max_connection_pool_size'],
  :log_dir   => log_dir,
  :udp_socket_pool_size => bifrost_config['stats_hero_udp_socket_pool_size'],
  :estatsd_host => estatsd_host,
  :estatsd_port => estatsd_port
}

template "#{service_dir}/etc/sys.config" do
  owner service_owner
  group service_group
  mode 0644
  variables(config_variables)
  notifies :restart, "service[oc_bifrost]", :delayed
end

template "#{service_dir}/etc/vm.args" do
  owner service_owner
  group service_group
  mode 0644
  notifies :restart, "service[oc_bifrost]", :delayed
end

# This is the script that will actually run the application.  It is
# enhanced from the standard Erlang release boot script in that it has
# support for running under runit.
template "#{service_dir}/bin/oc_bifrost" do
  source "run_script.sh.erb"
  owner service_owner
  group service_group
  mode 0755
  variables(config_variables)
  notifies :restart, "service[oc_bifrost]", :delayed
end

# These are some stock scripts that the boot script needs to call.
cookbook_file "#{service_dir}/bin/nodetool" do
  owner service_owner
  group service_group
  mode 0755
end

cookbook_file "#{service_dir}/bin/erl" do
  owner service_owner
  group service_group
  mode 0755
end

if !node['private_chef']
  # Drop off an rsyslog configuration
  template "/etc/rsyslog.d/30-oc_bifrost.conf" do
    source "erlang_app_rsyslog.conf.erb"
    owner "root"
    group "root"
    mode 0644
    variables(:log_file_path => "/var/log/oc_bifrost.log")
    notifies :restart, "service[rsyslog]"
  end
end

#
# Set up the actual service
#

runit_service 'oc_bifrost' do
  template_name "erlang_app" # Our common template
  if node['private_chef']
    down node['private_chef']['oc_bifrost']['ha']
  end
  options({
            :srv_dir => service_dir,
            :bin_name => 'oc_bifrost',

            # See http://smarden.org/runit/chpst.8.html

            # These are for the run script
            :run_setuidgid => service_owner,
            :run_envuidgid => service_group,

            # This is for the log-run script
            :log_setuidgid => "nobody"
          })
end

if node['private_chef']
  # Bootstrap me
  if node['private_chef']['bootstrap']['enable']
    include_recipe 'opscode-bifrost::database'
    execute "/opt/opscode/bin/private-chef-ctl start oc_bifrost" do
      retries 20
    end
  end

  # Everybody else is doing it ...
  add_nagios_hostgroup("oc_bifrost")
end