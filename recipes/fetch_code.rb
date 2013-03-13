app_name = node['app_name']

# This is where we'll check out the Git source code for the application
node.set[app_name]['src_dir'] = if node[app_name]['development_mode']
                                  "/vagrant"
                                else
                                  src = node['src_dir'] || begin
                                                             Chef::Log.fatal("Define node['src_dir']")
                                                             raise
                                                           end
                                  "#{src}/#{app_name}"
                                end

unless node[app_name]['development_mode']
  git "#{app_name}_db_source" do
    destination node[app_name]['src_dir']
    repository "git@github.com:opscode/#{app_name}.git"
    revision node[app_name]['revision']
    user "opscode"
    group "opscode"
  end
end
