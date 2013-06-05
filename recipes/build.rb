# Build from source when in development mode.
app_name = node['app_name']

raise "Build recipe can only be used in development mode!" unless node[app_name]['development_mode']

# In dev mode, source is mounted at /vagrant
src_dir = "/vagrant"
rel_dir = "#{src_dir}/rel/#{app_name}"

include_recipe "git"

# Encapsulate the logic for stopping the app service, rebuilding the
# app, and restarting the service (at the end of the Chef run)
ruby_block "rebuild_#{app_name}" do
  block do
    Chef::Log.info("Stopping #{app_name} service (if it exists) and rebuilding")
  end
  if File.directory?("#{node['runit']['sv_dir']}/#{app_name}")
    notifies :stop, "service[#{app_name}]", :immediately
  end

  notifies :run, "execute[rel_#{app_name}]", :immediately
  notifies :restart, "service[#{app_name}]", :delayed
  action :nothing
end

ruby_block "signal_rebuild" do
  block do
    Chef::Log.info("Signalling a rebuild in development mode")
  end
  notifies :create, "ruby_block[rebuild_#{app_name}]", :immediately
end

execute "distclean_#{app_name}" do
  # erlexec needs HOME env var to be set. If it's not set, it errors out.
  # This seems to happen when chef-client runs daemonized.
  unless ENV['HOME']
    Chef::Log.info("HOME is not set. Setting to /root.")
    environment({'HOME' => '/root'})
  end

  command "make distclean"
  cwd src_dir
  notifies :run, "execute[rel_#{app_name}]", :immediately
  action :nothing
end

execute "rel_#{app_name}" do
  # erlexec needs HOME env var to be set. If it's not set, it errors out.
  # This seems to happen when chef-client runs daemonized.
  unless ENV['HOME']
    Chef::Log.info("HOME is not set. Setting to /root.")
    environment({'HOME' => '/root'})
  end

  command "make relclean rel"
  cwd src_dir
  action :nothing
end

# TODO: I don't really like this
#
# This is to ensure that we can "link" our 'etc' configuration
# directory into the release directory.  When we're in development
# mode, this directory is on the /vagrant filesystem, and we
# apparently can't make links into it.  As a work around, we'll just
# copy the final release into the appropriate place.
execute "rm -Rf #{node[app_name]['srv_dir']}" do
  only_if "test -d #{node[app_name]['srv_dir']}"
end
execute "cp -R #{rel_dir} #{File.dirname(node[app_name]['srv_dir'])}"
execute "chown -R opscode:opscode #{node[app_name]['srv_dir']}"

# link "link_release_to_service_directory" do
#   to rel_dir
#   target_file node[app_name]['srv_dir']
#   owner "opscode"
#   group "opscode"
# end
