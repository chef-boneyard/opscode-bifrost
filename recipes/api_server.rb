# The Bifrost API service
#
# Pulls in erlang service requirements.
# In development mode, builds from source, otherwise
# deploys from build artifact.
# Then configures the service.
app_name = node['app_name']

include_recipe "logrotate::default"
include_recipe "opscode-bifrost::erlang_application_base"

if node[app_name]['development_mode']
  # In dev we build from source
  include_recipe "opscode-bifrost::build"
else
  # Otherwise we deploy from artifact
  include_recipe "opscode-bifrost::deploy"
end

# Generic OTP service config
include_recipe "opscode-bifrost::service"

# Bifrost-specific config
config_variables = {
  :ip                   => node[app_name]['host'],
  :port                 => node[app_name]['port'],
  :superuser_id         => node[app_name]['superuser_id'],
  :console_log_size     => node[app_name]['console_log_size'],
  :console_log_count    => node[app_name]['console_log_count'],
  :error_log_size       => node[app_name]['error_log_size'],
  :error_log_count      => node[app_name]['error_log_count'],
  :db_host              => node[app_name]['database']['host'],
  :db_port              => node[app_name]['database']['port'],
  :db_name              => node[app_name]['database']['name'],
  :db_user              => node[app_name]['database']['users']['owner']['name'],
  :db_pass              => node[app_name]['database']['users']['owner']['password'],
  :pool_size            => node[app_name]['database']['connection_pool_size'],
  :max_pool_size        => node[app_name]['database']['max_connection_pool_size'],
  :log_dir              => node[app_name]['log_dir'],
  :udp_socket_pool_size => node[app_name]['stats_hero_udp_socket_pool_size'],
  :estatsd_host         => node[app_name]['estatsd_host'],
  :estatsd_port         => node['stats_hero']['estatsd_port']
}

template "#{node[app_name]['etc_dir']}/sys.config" do
  owner "opscode"
  group "opscode"
  mode 0644
  variables(config_variables)
  notifies :restart, "service[#{app_name}]", :delayed
end
