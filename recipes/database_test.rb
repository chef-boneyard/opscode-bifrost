include_recipe "opscode-heimdall::pgtap"
include_recipe "opscode-heimdall::pg_prove"

execute "install_pgtap_in_database" do
  command """
    psql --dbname #{node['oc_heimdall']['database']['name']} \
         --command \"CREATE EXTENSION IF NOT EXISTS pgtap WITH VERSION '#{node['pgtap']['version']}';\"
    """
  user "postgres"
end
