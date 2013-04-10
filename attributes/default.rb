if default['private_chef']
  bifrost_default = default['private_chef']['oc_bifrost']
  bifrost_default['srv_dir'] = "/var/opt/opscode/oc_bifrost"
  bifrost_default['log_dir'] = "/var/log/opscode/oc_bifrost"
else
  bifrost_default = default['oc_bifrost']

  # These attributes are used by Opscode's 'erlang_binary' cookbook
  default['oc-authz-pedant']['revision'] = "master"
  default['stats_hero']['estatsd_port'] = 3344
  db_port = 5432
  default['postgresql']['config']['port']    = db_port
  bifrost_default['database']['port'] = db_port
  default["erlang_version"] = "erlang_R15B01"
  default["rebar_version"]  = "2.0.0"

  bifrost_default['srv_dir'] = "/srv/oc_bifrost"
  bifrost_default['log_dir'] = "/var/log/oc_bifrost"
end

# The Git commit / tag / branch you want to check out and build from
bifrost_default['revision'] = "master"
bifrost_default['host'] = "0.0.0.0"
bifrost_default['port'] = 5960
bifrost_default['stats_hero_udp_socket_pool_size'] = 20
bifrost_default['database']['name'] = "bifrost"

# I think there's Chef 11 syntax to make this possible without
# repeating, but I don't think we've got Chef 11 in prod just yet.

bifrost_default['database']['connection_pool_size'] = 5
bifrost_default['database']['max_connection_pool_size'] = 40
bifrost_default['database']['users']['owner']['name'] = "bifrost"
bifrost_default['database']['users']['owner']['password'] = "challengeaccepted"
bifrost_default['database']['users']['read_only']['name'] = "bifrost_ro"
bifrost_default['database']['users']['read_only']['password'] = "foreveralone"
