# Hosted chef service instance.
app = 'oc_bifrost'

include_recipe "opscode-bifrost::ohc-common"

# In hosted chef we have a 'vips' data bag to find
# estatsd and DB.
vips = data_bag_item("vips", node.chef_environment)

# estatsd host is 1) node override or 2) VIP
node.default[app]['estatsd_host'] = if node['stats_hero'] && node['stats_hero']['estatsd_host']
  node['stats_hero']['estatsd_host']
else
  vips['estatsd_host']
end

# DB host is 1) node override or 2) VIP or 3) role query
node.default[app]['database']['host'] = if node[app]['database']['host']
  Chef::Log.info("Using node attribute for #{app} DB host")
  node[app]['database']['host']
elsif vips["bifrost_pgsql_ip"]
  Chef::Log.info("Using VIP for #{app} DB host")
  vips["bifrost_pgsql_ip"]
else
  Chef::Log.info("Using role search for #{app} DB host")
  search(:node, "chef_environment:#{node.chef_environment} AND role:bifrost-pgsql")[0].ipaddress
end

# Superuser ID is in the environments data bag
env = data_bag_item("environments", node.chef_environment)
node.default[app]['superuser_id'] = env['opscode-authz-superuser-id']

# DB passwords are in the secrets data bag.
secrets = data_bag_item("secrets", node.chef_environment)
node.default[app]['database']['users']['owner']['password'] = secrets[app]['db_rw_password']
node.default[app]['database']['users']['read_only']['password'] = secrets[app]['db_ro_password']

# Hipchat key
node.default[app]['hipchat_key'] = data_bag_item("environments", node.chef_environment)["hipchat_key"]

node.default[app]['aws_bucket'] = 'opscode-ci'

include_recipe "opscode-bifrost::api_server"
