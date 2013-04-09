# Log Directories
node.set['oc_bifrost']['log_dir'] = "/var/log/oc_bifrost"
node.set['oc_bifrost']['sasl_dir'] = "#{node['oc_bifrost']['log_dir']}/sasl"

# Service Directory
#
# This is the preferred location at which the completed Erlang release
# will be found.  This will be a link to the 'rel_dir', defined below
node.set['oc_bifrost']['srv_dir'] = "/srv/oc_bifrost"


# Source Directory
#
# This is where we'll check out the Git source code for the application
node.set['oc_bifrost']['src_dir'] = if node['oc_bifrost']['development_mode']
                                  "/vagrant"
                                else
                                  src = node['src_dir'] || begin
                                                             Chef::Log.fatal("Define node['src_dir']")
                                                             raise
                                                           end
                                  "#{src}/oc_bifrost"
                                end

# Release Directory
#
# The directory in which the release will be built.  This is in a Git
# checkout, currently
node.set['oc_bifrost']['rel_dir'] = "#{node['oc_bifrost']['src_dir']}/rel/oc_bifrost"

# Configuration Directory
#
# We'll store the release config files in a separate directory (and
# alongside the config files of our other software).  This will
# prevent them from getting nuked with successive rebuilds of the
# release.  We'll link them in later.
node.set['oc_bifrost']['etc_dir'] = "/var/opt/opscode/oc_bifrost/etc"

# Binary Directory
#
# This is where the release binaries will be dropped off
node.set['oc_bifrost']['bin_dir'] = "#{node['oc_bifrost']['srv_dir']}/bin"

# src_dir and rel_dir are created by other means (during git checkout
# and release generation, respectively).  srv_dir needs to be created
# later a link to rel_dir.  bin_dir needs to be created after srv_dir
# is present
['log_dir', 'sasl_dir', 'etc_dir'].each do |dir|
  directory node['oc_bifrost'][dir] do
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
