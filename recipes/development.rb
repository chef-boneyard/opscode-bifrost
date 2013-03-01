
# opscode-dev-shim currently sets a "dev_mode" attribute, but in a way
# that can't be overridden (yet?) by Test Kitchen.  Until that's fixed
# up, we'll just use our own special flag.
node.set['oc_heimdall']['development_mode'] = true

include_recipe "opscode-heimdall::default"
include_recipe "opscode-heimdall::database_test"
include_recipe "opscode-heimdall::pedant"
