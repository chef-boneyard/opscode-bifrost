# Hosted chef service instance.
app = 'oc_bifrost'

# In hosted chef we have a 'vips' data bag to find
# estatsd and DB.
vips = data_bag_item("vips", node[:app_environment])

# estatsd host is 1) node override or 2) VIP
node[app]['estatsd_host'] = if node['stats_hero'] && node['stats_hero']['estatsd_host']
   node['stats_hero']['estatsd_host']
else
  vips['estatsd_host']
end

# DB host is 1) node override or 2) VIP or 3) role query
node[app]['database']['host'] = if node[app]['database']['host']
  Chef::Log.info("Using node attribute for #{app} DB host")
  node[app]['database']['host']
elsif vips["bifrost_pgsql_ip"]
  Chef::Log.info("Using VIP for #{app} DB host")
  vips["bifrost_pgsql_ip"]
else
  Chef::Log.info("Using role search for #{app} DB host")
  search(:node, "role:bifrost-pgsql")[0].ipaddress
end

# Superuser ID is in the environments data bag
env = data_bag_item("environments", node[:app_environment])
node[app]['superuser_id'] = env['opscode-authz-superuser-id']

include_recipe "opscode-bifrost::api_server"
