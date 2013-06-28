# The Bifrost API service
#
# In development mode, build from source; otherwise deploys from build
# artifact. Then configure the service.
#
# Uses otp_service which pulls defaults from node[app_name].
# See otp_service.rb for details.
#

app_name = 'oc_bifrost'

# The otp_service resource handles all the generic
# OTP service logic:
# - build from source or download from S3 (depending on dev mode)
# - deploy build artifact (and send hipchat notification)
# - configure generic OTP service
#
config_variables = {
  :ip                   => node[app_name]['host'],
  :port                 => node[app_name]['port'],
  :superuser_id         => node[app_name]['superuser_id'],
  :console_log_mb       => node[app_name]['console_log_mb'],
  :console_log_count    => node[app_name]['console_log_count'],
  :error_log_mb         => node[app_name]['error_log_mb'],
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

opscode_erlang_otp_service app_name do
  action :deploy
  app_environment node['app_environment']
  revision node[app_name]['revision']
  source node[app_name]['source']
  development_mode node[app_name]['development_mode']
  aws_bucket node[app_name]['aws_bucket']
  aws_access_key_id node[app_name]['aws_access_key_id']
  aws_secret_access_key node[app_name]['aws_secret_access_key']
  root_dir node[app_name]['srv_root']
  estatsd_host node[app_name]['estatsd_host']
  hipchat_key node[app_name]['hipchat_key']
  log_dir node[app_name]['log_dir']
  console_log_count node[app_name]['console_log_count']
  console_log_mb node[app_name]['console_log_mb']
  error_log_count node[app_name]['error_log_count']
  error_log_mb node[app_name]['error_log_mb']
  owner node[app_name]['owner']
  group node[app_name]['group']
  sys_config config_variables
end
