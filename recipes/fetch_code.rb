unless node['oc_heimdall']['development_mode']
  # If dev mode, we assume we're running in Vagrant, and thus already
  # have the code in /vagrant.  No need to fetch.

  include_recipe 'git'

  # Grab the source
  git "oc_heimdall" do
    destination node['oc_heimdall']['source_dir']
    repository "git@github.com:opscode/oc_heimdall.git"
    revision node['oc_heimdall']['revision']
    user "opscode"
    group "opscode"

    # if File.directory?("#{node['oc_heimdall']['source_dir']}/rel/heimdall")
    #   notifes :stop, "service[oc_heimdall]", :immediately
    # end

    # notifies :run, "execute[build-heimdall]", :immediately
    # notifies :restart, "service[oc_heimdall]", :delayed
  end
end
