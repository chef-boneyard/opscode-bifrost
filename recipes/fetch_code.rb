unless node['opscode-authz']['development_mode']
  # If dev mode, we assume we're running in Vagrant, and thus already
  # have the code in /vagrant.  No need to fetch.

  include_recipe 'git'

  # Grab the source
  git "oc_authz" do
    destination node['opscode-authz']['source_dir']
    repository "git@github.com:opscode/oc_authz.git"
    revision node['opscode-authz']['revision']
    user "opscode"
    group "opscode"

    # if File.directory?("#{node['opscode_authz']['source_dir']}/rel/authz")
    #   notifes :stop, "service[opscode-authz]", :immediately
    # end

    # notifies :run, "execute[build-authz]", :immediately
    # notifies :restart, "service[opscode-authz]", :delayed
  end
end
