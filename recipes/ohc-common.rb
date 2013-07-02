# Hosted chef common recipe
app = 'oc_bifrost'

#
# In OHC we get the revision to deploy from the env data bag.
#
env = data_bag_item("environments", node.chef_environment)
bifrost_env = env[app] || (raise "missing #{app} key in #{node.chef_environment} env data bag item")
node.default[app]['revision'] = bifrost_env['revision'] || (raise "missing revision in #{app} env data")
node.default[app]['build-revision'] = bifrost_env['build-revision'] || (raise "missing build-revision in #{app} env data")
