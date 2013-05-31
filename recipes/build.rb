# TODO: pull this up higher
include_recipe "git"

app_name = node['app_name']

# Encapsulate the logic for stopping the app service, rebuilding the
# app, and restarting the service (at the end of the Chef run)
ruby_block "rebuild_#{app_name}" do
  block do
    Chef::Log.info("Stopping #{app_name} service (if it exists) and rebuilding")
  end
  if File.directory?("#{node['runit']['sv_dir']}/#{app_name}")
    notifies :stop, "service[#{app_name}]", :immediately
  end

  if node[app_name]['development_mode']
    # Don't fetch deps again, just rebuild the release; if you add
    # another dep, either manually call 'rebar get-deps', or just
    # rebuild the VM
    notifies :run, "execute[rel_#{app_name}]", :immediately
  else
    notifies :run, "execute[distclean_#{app_name}]", :immediately
  end

  notifies :restart, "service[#{app_name}]", :delayed
  action :nothing
end

# Fetch the code for the application from the Git repository.  If
# running in development mode, we assume the code is already present
# (e.g., is in /vagrant) and bypass the code retrieval
if node[app_name]['development_mode']
  # Not fetching code, but we do need to send the appropriate signals
  # to stop the service and rebuild it, though

  ruby_block "signal_rebuild" do
    block do
      Chef::Log.info("Signalling a rebuild in development mode")
    end
    notifies :create, "ruby_block[rebuild_#{app_name}]", :immediately
  end
else
  # Grab the source
  git app_name do
    destination node[app_name]['src_dir']
    repository "git@github.com:opscode/#{app_name}.git"
    revision node[app_name]['revision']
    user "opscode"
    group "opscode"
    notifies :create, "ruby_block[rebuild_#{app_name}]", :immediately
  end
end

execute "distclean_#{app_name}" do
  # erlexec needs HOME env var to be set. If it's not set, it errors out.
  # This seems to happen when chef-client runs daemonized.
  unless ENV['HOME']
    Chef::Log.info("HOME is not set. Setting to /root.")
    environment({'HOME' => '/root'})
  end

  command "make distclean"
  cwd node[app_name]['src_dir']
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
  cwd node[app_name]['src_dir']
  action :nothing
end

if node[app_name]['development_mode']
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
  execute "cp -R #{node[app_name]['rel_dir']} #{File.dirname(node[app_name]['srv_dir'])}"
  execute "chown -R opscode:opscode #{node[app_name]['srv_dir']}"
else
  # Otherwise, we just link things up and we're done with it.
  link "link_release_to_service_directory" do
    to node[app_name]['rel_dir']
    target_file node[app_name]['srv_dir']
    owner "opscode"
    group "opscode"
  end
end

