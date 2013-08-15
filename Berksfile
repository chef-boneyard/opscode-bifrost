chef_api "https://opsmaster-api.opscode.us/organizations/preprod", node_name: ENV['USER'], client_key: "#{ENV['HOME']}/.chef/#{ENV['USER']}-opsmaster.pem"
site :opscode

metadata

cookbook "opscode-dev-shim", git: "git@github.com:opscode-cookbooks/opscode-dev-shim.git"
cookbook "opscode-pedant", git: "git@github.com:opscode-cookbooks/opscode-pedant.git"
cookbook "opscode-ruby", git: "git@github.com:opscode-cookbooks/opscode-ruby.git"

# This isn't public just yet... we'll let it bake a bit before
# unleashing it on the world
cookbook "sqitch", git: "git@github.com:opscode-cookbooks/sqitch.git"
