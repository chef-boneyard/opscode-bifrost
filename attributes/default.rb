app_name = 'oc_bifrost'

# App source
# By default, in development mode, pull source from git repo.
# Set to a local checkout to make changes, e.g. "/home/<user>/src/oc_bifrost".
# Set to "/vagrant" to use a vagrant mount.
default[app_name]['source'] = "git@github.com:opscode/oc_bifrost.git"

# Revision: git branch/sha/tag when pulling from git. Otherwise, artifact
# revision when pulling from S3.
# Note: sometimes git notifies for changes when using a tag or branch
# even though the repo has not changed (causing a service restart).
default[app_name]['revision'] = "master"
default[app_name]['schema-version'] = "1.1.6"

# Deployment
default[app_name]['srv_root'] = '/srv'
default[app_name]['log_dir'] = "/var/log/#{app_name}"
default[app_name]['owner'] = 'opscode'
default[app_name]['group'] = 'opscode'

# Basic service config
default[app_name]['host'] = "0.0.0.0"
default[app_name]['port'] = 5959
default[app_name]['superuser_id'] = '00000000000000000000000000000000'

default['oc-authz-pedant']['revision'] = "master"

# Logging. Bifrost is currently rather chatty: default to ~2G of logs on the box.
default[app_name]['log_dir'] = "/var/log/oc_bifrost"
default[app_name]['console_log_mb'] = 400
default[app_name]['console_log_count'] = 5
# Keep ~100 MB of error logs
default[app_name]['error_log_mb'] = 20
default[app_name]['error_log_count'] = 5

# estatsd
default[app_name]['estatsd_host'] = '127.0.0.1'
default[app_name]['stats_hero_udp_socket_pool_size'] = 20
default['stats_hero']['estatsd_port'] = 3344

# DB
default['sqitch']['engine'] = 'pg'
default[app_name]['database']['name'] = "bifrost"
db_port = 5432
default['postgresql']['config']['port'] = db_port
default[app_name]['database']['port'] = db_port

default[app_name]['database']['connection_pool_size']     = 100
default[app_name]['database']['max_connection_pool_size'] = 100

default[app_name]['database']['users']['owner']['name'] = "bifrost"
default[app_name]['database']['users']['owner']['password'] = "challengeaccepted"
default[app_name]['database']['users']['read_only']['name'] = "bifrost_ro"
default[app_name]['database']['users']['read_only']['password'] = "foreveralone"

# These attributes are used by Opscode's 'erlang_binary' cookbook
default["erlang_version"] = "erlang_R15B01"
default["rebar_version"]  = "2.0.0"
