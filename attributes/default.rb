default['app_name'] = "oc_bifrost"


# The Git commit / tag / branch you want to check out and build from
default['oc_bifrost']['revision'] = "038f978bb074aa67fd0a4ea1e01d8f0e264b61c1" # 1.3.0
# When deploying from artifact; Note that sqitch uses this value for
# the schema version to deploy to, in order to keep things in sync.
default['oc_bifrost']['build-revision'] = "1.3.0"

default['oc-authz-pedant']['revision'] = "master"

default['oc_bifrost']['host'] = "0.0.0.0"
default['oc_bifrost']['port'] = 5959

default['oc_bifrost']['superuser_id'] = '00000000000000000000000000000000'

# Bifrost is currently rather chatty: default to ~2G of logs on the box
default['oc_bifrost']['log_rotation']['console_log']['file_maxbytes'] = (1024 * 1024 * 400) # 400M
default['oc_bifrost']['log_rotation']['console_log']['num_to_keep']   = 5
# Keep ~100 MB of error logs
default['oc_bifrost']['log_rotation']['error_log']['file_maxbytes'] = (1024 * 1024 * 20) # 20M
default['oc_bifrost']['log_rotation']['error_log']['num_to_keep']   = 5

default['oc_bifrost']['stats_hero_udp_socket_pool_size'] = 20
default['stats_hero']['estatsd_port'] = 3344

default['sqitch']['engine'] = 'pg'
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
