# Hosted chef common recipe
app = 'oc_bifrost'

#
# In OHC we get the revision to deploy from the env data bag.
#
env = data_bag_item("environments", node[:app_environment])
bifrost_env = env[app] || (raise "missing #{app} key in #{node[:app_environment]} env data bag item")
node.default[app]['revision'] = bifrost_env['revision'] || (raise "missing revision in oc_erchef env data")
