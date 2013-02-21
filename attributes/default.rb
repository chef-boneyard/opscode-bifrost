default['oc_heimdall']['user']  = "opscode"
default['oc_heimdall']['group'] = "opscode"

# The Git commit / tag / branch you want to check out and build from
default['oc_heimdall']['revision'] = "master"

default['oc_heimdall']['database']['name'] = "heimdall"
default['oc_heimdall']['database']['users']['owner']['name'] = "heimdall"
default['oc_heimdall']['database']['users']['owner']['password'] = "challengeaccepted"
default['oc_heimdall']['database']['users']['read_only']['name'] = "heimdall_ro"
default['oc_heimdall']['database']['users']['read_only']['password'] = "foreveralone"

# These attributes are used by Opscode's 'erlang_binary' cookbook
default["erlang_version"] = "erlang_R15B01"
default["rebar_version"]  = "2.0.0"
