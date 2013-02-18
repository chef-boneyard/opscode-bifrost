
# opscode-dev-shim currently sets a "dev_mode" attribute, but in a way
# that can't be overridden (yet?) by Test Kitchen.  Until that's fixed
# up, we'll just use our own special flag.
node.set['opscode-authz']['development_mode'] = true

include_recipe "opscode-authz::default"
include_recipe "opscode-authz::database_test"

# TODO: eventually include oc-authz-pedant, too
