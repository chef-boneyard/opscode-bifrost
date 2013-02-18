default['opscode-authz']['user']  = "opscode"
default['opscode-authz']['group'] = "opscode"

# The Git commit / tag / branch you want to check out and build from
default['opscode-authz']['revision'] = "master"

default['opscode-authz']['database']['name'] = "authz"
default['opscode-authz']['database']['users']['owner']['name'] = "authz"
default['opscode-authz']['database']['users']['owner']['password'] = "challengeaccepted"
default['opscode-authz']['database']['users']['read_only']['name'] = "authz_ro"
default['opscode-authz']['database']['users']['read_only']['password'] = "foreveralone"

# These attributes are used by Opscode's 'erlang_binary' cookbook
default["erlang_version"] = "erlang_R15B01"
default["rebar_version"]  = "2.0.0"
