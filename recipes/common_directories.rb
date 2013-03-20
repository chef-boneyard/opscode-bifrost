
# TODO: Extract this source directory to a common recipe that can be
# used across our infrastructure.

# This is a common place where we can download and build project source code
node.set['src_dir'] = "/usr/local/src"
node.set['db_src_dir'] = "/usr/local/db_src"

directory node['src_dir'] do
  owner "opscode"
  group "opscode"
  mode "0755"
  recursive true
end

directory node['db_src_dir'] do
  owner "opscode"
  group "opscode"
  mode "0755"
  recursive true
end
