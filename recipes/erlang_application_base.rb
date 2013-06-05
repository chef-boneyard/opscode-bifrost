app_name = node['app_name'] || begin
                                 Chef::Log.fatal("Application name not defined!  Set node['app_name']")
                                 raise
                               end

# Required
include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

# Log Directories
node.set[app_name]['log_dir'] = "/var/log/#{app_name}"
node.set[app_name]['sasl_dir'] = "#{node[app_name]['log_dir']}/sasl"

# Service Directory
#
# This is the preferred location at which the completed Erlang release
# will be found.  This will be a link to the 'rel_dir', defined below
node.set[app_name]['srv_dir'] = "/srv/#{app_name}"

# Configuration Directory
#
# We'll store the release config files in a separate directory (and
# alongside the config files of our other software).  This will
# prevent them from getting nuked with successive rebuilds of the
# release.  We'll link them in later.
node.set[app_name]['etc_dir'] = "/var/opt/opscode/#{app_name}/etc"

# Binary Directory
#
# This is where the release binaries will be dropped off
node.set[app_name]['bin_dir'] = "#{node[app_name]['srv_dir']}/bin"

# src_dir and rel_dir are created by other means (during git checkout
# and release generation, respectively).  srv_dir needs to be created
# later a link to rel_dir.  bin_dir needs to be created after srv_dir
# is present
['log_dir', 'sasl_dir', 'etc_dir'].each do |dir|
  directory node[app_name][dir] do
    owner "opscode"
    group "opscode"
    mode "0755"
    recursive true
  end
end

# TODO: Consider creating all the resources for the remaining
# directories / links here and have their execution triggered via
# notifications

# TODO: Consider an "opscode_directory" resource that sets up the
# proper owner, group, and mode for our directories, since they're the
# same.
