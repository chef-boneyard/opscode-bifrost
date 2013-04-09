# This is where we'll check out the Git source code for the application
# The first one, src_dir, is for building the service.
# The second one, db_src_dir, is for initializing the db.
node.set['oc_bifrost']['src_dir'] = if node['oc_bifrost']['development_mode']
                                  "/vagrant"
                                else
                                  src = node['src_dir'] || begin
                                                             Chef::Log.fatal("Define node['src_dir']")
                                                             raise
                                                           end
                                  "#{src}/oc_bifrost"
                                end

node.set['oc_bifrost']['db_src_dir'] = if node['oc_bifrost']['development_mode']
                                  "/vagrant"
                                else
                                  src = node['db_src_dir'] || begin
                                                             Chef::Log.fatal("Define node['db_src_dir']")
                                                             raise
                                                           end
                                  "#{src}/oc_bifrost"
                                end

unless node['oc_bifrost']['development_mode']
  git "oc_bifrost_db_source" do
    destination node['oc_bifrost']['db_src_dir']
    repository "git@github.com:opscode/oc_bifrost.git"
    revision node['oc_bifrost']['revision']
    user "opscode"
    group "opscode"
  end
end
