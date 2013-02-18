
# TODO: Extract this source directory to a common recipe that can be
# used across our infrastructure.

node.set['source_directory'] = "/usr/local/src"

directory node['source_directory'] do
  owner "opscode"
  group "opscode"
  mode "0755"
  recursive true
end
