app_name = node['app_name']
repo_name = "oc-authz-pedant" # should be oc-heimdall-pedant, but we haven't renamed yet :(

node.set[app_name]['pedant_etc_dir'] = "/var/opt/opscode/#{repo_name}/etc"
directory node[app_name]['pedant_etc_dir'] do
  owner "opscode"
  group "opscode"
  mode "0755"
  recursive true
end

git "#{node['src_dir']}/#{repo_name}" do
  repository "git@github.com:opscode/#{repo_name}.git"
  revision node[app_name]['pedant_revision']
  user "opscode"
  group "opscode"
end

template "#{node[app_name]['pedant_etc_dir']}/pedant_config.rb" do
  owner "opscode"
  group "opscode"
  mode "0644"
  variables(:host => node[app_name]['host'],
            :port => node[app_name]['port'])
end

gem_package "bundler"

execute "bundle install" do
  cwd "#{node['src_dir']}/#{repo_name}"
end

# NOTE: to actually run Pedant, we'll need to use the embedded Ruby that Chef uses
#
# For automated testing (a la Test Kitchen), we'll need to use
#
# export PATH="/opt/chef/embedded/bin:$PATH"
# cd /usr/local/src/oc-authz-pedant
# bin/oc-authz-pedant --config /var/opt/opscode/oc-authz-pedant/etc/pedant_config.rb
