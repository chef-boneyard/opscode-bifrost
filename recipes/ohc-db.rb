# Hosted chef instance of database.
app = 'oc_bifrost'

#
# In hosted chef, we have a secrets data bag with the passwords.
#
secrets = data_bag_item("secrets", node[:app_environment])
node[app]['database']['users']['owner']['password'] = secrets[app]['db_rw_password']
node[app]['database']['users']['read_only']['password'] = secrets[app]['db_ro_password']

include_recipe "opscode-bifrost::database"
