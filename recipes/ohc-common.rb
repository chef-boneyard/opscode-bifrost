# Hosted chef common recipe
app = 'oc_bifrost'

#
# In OHC we get the revision to deploy from the env data bag.
#
env = data_bag_item("environments", node.chef_environment)
canary = data_bag_item("canary", node.chef_environment)
bifrost_env = env[app] || (raise "missing #{app} key in #{node.chef_environment} env data bag item")

revision = if tagged?('canary') and canary['oc_bifrost_revision']
             canary['oc_bifrost_revision']
           else
             bifrost_env['revision'] || (raise "missing revision in #{app} env data")
           end

node.default[app]['revision'] = bifrost_env['revision'] || (raise "missing revision in #{app} env data")
node.default[app]['schema-version'] = bifrost_env['schema-version'] || (raise "missing schema-version in #{app} env data")
