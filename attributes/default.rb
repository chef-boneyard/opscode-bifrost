default['app_name'] = "oc_heimdall"


# The Git commit / tag / branch you want to check out and build from
default['oc_heimdall']['revision'] = "master"

default['oc_heimdall']['host'] = "0.0.0.0"
default['oc_heimdall']['port'] = 5959

default['oc_heimdall']['database']['name'] = "heimdall"

# These may end up coming from opscode-postgresql?
default['oc_heimdall']['database']['host'] = "127.0.0.1"

# I think there's Chef 11 syntax to make this possible without
# repeating, but I don't think we've got Chef 11 in prod just yet.

db_port = 5432
default['postgresql']['config']['port']    = db_port
default['oc_heimdall']['database']['port'] = db_port

default['oc_heimdall']['database']['connection_pool_size'] = 5

default['oc_heimdall']['database']['users']['owner']['name'] = "heimdall"
default['oc_heimdall']['database']['users']['owner']['password'] = "challengeaccepted"
default['oc_heimdall']['database']['users']['read_only']['name'] = "heimdall_ro"
default['oc_heimdall']['database']['users']['read_only']['password'] = "foreveralone"

default['oc_heimdall']['pedant_revision'] = "master"

# These attributes are used by Opscode's 'erlang_binary' cookbook
default["erlang_version"] = "erlang_R15B01"
default["rebar_version"]  = "2.0.0"
