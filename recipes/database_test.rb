include_recipe "opscode-bifrost::pgtap"
include_recipe "opscode-bifrost::pg_prove"

execute "install_pgtap_in_database" do
  command """
    psql --dbname #{node['oc_bifrost']['database']['name']} \
         --command \"CREATE EXTENSION IF NOT EXISTS pgtap WITH VERSION '#{node['pgtap']['version']}';\"
    """
  user "postgres"
end
