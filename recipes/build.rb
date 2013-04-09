# Encapsulate the logic for stopping the app service, rebuilding the
# app, and restarting the service (at the end of the Chef run)
ruby_block "rebuild_oc_bifrost" do
  block do
    Chef::Log.info("Stopping oc_bifrost service (if it exists) and rebuilding")
  end

  if node['oc_bifrost']['development_mode']
    # Don't fetch deps again, just rebuild the release; if you add
    # another dep, either manually call 'rebar get-deps', or just
    # rebuild the VM
    notifies :run, "execute[rel_oc_bifrost]", :immediately
  else
    notifies :run, "execute[distclean_oc_bifrost]", :immediately
  end

  action :nothing
end

# Fetch the code for the application from the Git repository.  If
# running in development mode, we assume the code is already present
# (e.g., is in /vagrant) and bypass the code retrieval
if node['oc_bifrost']['development_mode']
  # Not fetching code, but we do need to send the appropriate signals
  # to stop the service and rebuild it, though

  ruby_block "signal_rebuild" do
    block do
      Chef::Log.info("Signalling a rebuild in development mode")
    end
    notifies :create, "ruby_block[rebuild_oc_bifrost]", :immediately
  end
else
  # Grab the source
  git 'oc_bifrost' do
    destination node['oc_bifrost']['src_dir']
    repository "git@github.com:opscode/oc_bifrost.git"
    revision node['oc_bifrost']['revision']
    user "opscode"
    group "opscode"
    notifies :create, "ruby_block[rebuild_oc_bifrost]", :immediately
  end
end

execute "distclean_oc_bifrost" do
  command "make distclean"
  cwd node['oc_bifrost']['src_dir']
  notifies :run, "execute[rel_oc_bifrost]", :immediately
  action :nothing
end

execute "rel_oc_bifrost" do
  command "make relclean rel"
  cwd node['oc_bifrost']['src_dir']
  action :nothing
end

if node['oc_bifrost']['development_mode']
  # TODO: I don't really like this
  #
  # This is to ensure that we can "link" our 'etc' configuration
  # directory into the release directory.  When we're in development
  # mode, this directory is on the /vagrant filesystem, and we
  # apparently can't make links into it.  As a work around, we'll just
  # copy the final release into the appropriate place.
  execute "rm -Rf #{node['oc_bifrost']['srv_dir']}" do
    only_if "test -d #{node['oc_bifrost']['srv_dir']}"
  end
  execute "cp -R #{node['oc_bifrost']['rel_dir']} #{File.dirname(node['oc_bifrost']['srv_dir'])}"
  execute "chown -R opscode:opscode #{node['oc_bifrost']['srv_dir']}"
else
  # Otherwise, we just link things up and we're done with it.
  link "link_release_to_service_directory" do
    to node['oc_bifrost']['rel_dir']
    target_file node['oc_bifrost']['srv_dir']
    owner "opscode"
    group "opscode"
  end
end
