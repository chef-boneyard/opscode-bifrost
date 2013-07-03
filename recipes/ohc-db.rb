# Hosted chef instance of database.
app = 'oc_bifrost'

include_recipe "opscode-bifrost::ohc-common"

#
# In hosted chef, we have a secrets data bag with the passwords.
#
secrets = data_bag_item("secrets", node.chef_environment)
node.default[app]['database']['users']['owner']['password'] = secrets[app]['db_rw_password']
node.default[app]['database']['users']['read_only']['password'] = secrets[app]['db_ro_password']

include_recipe "opscode-bifrost::database"
