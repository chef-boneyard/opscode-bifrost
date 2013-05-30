default['app_name'] = "oc_bifrost"


# The Git commit / tag / branch you want to check out and build from
default['oc_bifrost']['revision'] = "1.1.4"

default['oc-authz-pedant']['revision'] = "master"

default['oc_bifrost']['host'] = "0.0.0.0"
default['oc_bifrost']['port'] = 5959

# Bifrost is currently rather chatty: default to ~2G of logs on the box
default['oc_bifrost']['console_log_size']  = (1024 * 1024 * 400) # 400 MB (measured in bytes)
default['oc_bifrost']['console_log_count'] = 5
# Keep ~100 MB of error logs
default['oc_bifrost']['error_log_size']  = (1024 * 1024 * 20) # 20 MB (measured in bytes)
default['oc_bifrost']['error_log_count'] = 5

default['oc_bifrost']['stats_hero_udp_socket_pool_size'] = 20
default['stats_hero']['estatsd_port'] = 3344

default['oc_bifrost']['database']['name'] = "bifrost"

# I think there's Chef 11 syntax to make this possible without
# repeating, but I don't think we've got Chef 11 in prod just yet.

db_port = 5432
default['postgresql']['config']['port']    = db_port
default['oc_bifrost']['database']['port'] = db_port

default['oc_bifrost']['database']['connection_pool_size']     = 100
default['oc_bifrost']['database']['max_connection_pool_size'] = 100

default['oc_bifrost']['database']['users']['owner']['name'] = "bifrost"
default['oc_bifrost']['database']['users']['owner']['password'] = "challengeaccepted"
default['oc_bifrost']['database']['users']['read_only']['name'] = "bifrost_ro"
default['oc_bifrost']['database']['users']['read_only']['password'] = "foreveralone"

# These attributes are used by Opscode's 'erlang_binary' cookbook
default["erlang_version"] = "erlang_R15B01"
default["rebar_version"]  = "2.0.0"
