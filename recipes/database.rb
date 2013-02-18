include_recipe "opscode-postgresql"

node['opscode-authz']['database']['users'].to_hash.each do |role, user|
  # Note: 'role' here is just the key this user's hash was stored
  # under in the node... we don't care (yet) what that is, we just
  # want to create the users.

  name = user['name']
  password = user['password']

  execute "create_db_user_#{name}" do
    command """
      psql --dbname template1 \
           --command \"CREATE ROLE #{name}
                       WITH LOGIN
                            ENCRYPTED PASSWORD '#{password}'\"
      """
    user "postgres"
    not_if """
      psql --dbname template1 \
           --tuples-only \
           --command \"SELECT rolname FROM pg_roles WHERE rolname='#{name}';\" \
      | grep #{name}
      """, :user => "postgres"
  end
end

# Extract the database name to make things a little less verbose here
database_name = node['opscode-authz']['database']['name']

execute "create_database" do
  command """
    createdb --template template0 \
             --encoding UTF-8 \
             --owner #{node['opscode-authz']['database']['users']['owner']['name']} \
             #{database_name}
    """
  user "postgres"
  not_if """
    psql --dbname template1 \
         --tuples-only \
         --command \"SELECT datname FROM pg_database WHERE datname='#{database_name}';\" \
    | grep #{database_name}
    """, :user => "postgres"
  notifies :run, "execute[migrate_database]", :immediately
end

# TODO: Properly grant permissions for the different users
# TODO: Properly set up configuration for users so they don't map to system users

# Currently this just does an install from scratch.  Eventually we
# will adopt a migration approach.  A front-runner is Sqitch
# (https://github.com/theory/sqitch), from the creator of pgTAP.
execute "migrate_database" do
  command "psql -d #{database_name} -f authz.sql"
  cwd "#{node['opscode-authz']['source_dir']}/schema/sql"
  user "postgres"

  # Once we're using proper migrations, we can just have this action
  # execute automatically, instead of being triggered only when a new
  # database is created
  action :nothing
end

################################################################################
# TODO:
#
# I would like to use the database[1] cookbook to do the database
# creation and installation, but there is currently a bug [2] in the
# postgresql [3] cookbook that prevents the relevant resources from
# working.  Bryan Berry has a fork [4] with some of the work against
# this bug done already, but it needs more work before we can use it;
# currently, it only works against Centos, and not Ubuntu.  See the
# pull request tracking this work [5].
#
# If we can make time, we should finish up the work for COOK-1614
# ourselves and contribute it back to the community.
#
#
# [1] https://github.com/opscode-cookbooks/database
# [2] http://tickets.opscode.com/browse/COOK-1614
# [3] https://github.com/opscode-cookbooks/postgresql
# [4] https://github.com/bryanwb/postgresql/tree/COOK-1614
# [5] https://github.com/opscode-cookbooks/postgresql/pull/11


# THIS is the line that doesn't end up working due to COOK-1614.
# Ideally once that bug is fixed, we'd just add this include_recipe to
# our opscode-postgresql cookbook (along with a dependency on the
# database cookbook) and be done with it.
#
#  include_recipe 'postgresql::ruby'

# TODO: ensure that the attribute structure used by the postgres
# cookbook is compatible with this connection hash... I'd like to just
# specify the information once and have it "just work".
#
# postgresql_connection_info = {:host => "127.0.0.1",
#                               :port => node['postgresql']['config']['port'],
#                               :username => 'postgres',
#                               :password => node['postgresql']['password']['postgres']}

# postgresql_database node['opscode-authz']['database']['name'] do
#   connection postgresql_connection_info
#   action :create
#   template 'DEFAULT'
#   encoding 'DEFAULT'
#   owner node['opscode-authz']['database']['owner']
#   notifies :query, "postgresql_database[install_schema]", :immediately
# end

# # TODO: IDEMPOTENCE
# postgresql_database "install_schema" do
#   connection postgresql_connection_info
#   database_name node['opscode-authz']['database']['name']
#   action :nothing
#   sql { ::File.open("/vagrant/schema/sql/authz.sql").read }
# end