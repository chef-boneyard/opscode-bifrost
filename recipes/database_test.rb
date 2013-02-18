include_recipe "opscode-authz::pgtap"
include_recipe "opscode-authz::pg_prove"

execute "install_pgtap_in_database" do
  command """
    psql --dbname #{node['opscode-authz']['database']['name']} \
         --command \"CREATE EXTENSION IF NOT EXISTS pgtap WITH VERSION '#{node['pgtap']['version']}';\"
    """
  user "postgres"
end
