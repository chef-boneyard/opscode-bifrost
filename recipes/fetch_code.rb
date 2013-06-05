# Checks out source code unless in dev mode.
app_name = 'oc_bifrost'


if node[app_name]['development_mode']
  node.set[app_name]['src_dir'] = "/vagrant"
else
  src_dir = "/usr/local/src"

  directory src_dir do
    owner "opscode"
    group "opscode"
    mode "0755"
    recursive true
  end

  node.set[app_name]['src_dir'] = "#{src_dir}/#{app_name}"

  git "#{app_name}_source" do
    destination node[app_name]['src_dir']
    repository "git@github.com:opscode/#{app_name}.git"
    revision node[app_name]['revision']
    user "opscode"
    group "opscode"
  end
end
