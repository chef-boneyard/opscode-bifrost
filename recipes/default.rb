#
# Cookbook Name:: opscode-authz
# Recipe:: default
#
# Copyright (C) 2013 Opscode
#
# All rights reserved - Do Not Redistribute

include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

# group node['opscode_authz']['group']
# user node['opscode_authz']['user'] do
#   group node['opscode_authz']['group']
#   system true
#   shell "/bin/bash"
# end

# # TODO: This is probably better expressed as an environment check instead
# unless node['opscode-authz']['build_dir'] == "/vagrant"
#   include_recipe 'git'

#   # Grab the source
#   git "opscode-authz" do
#     destination node['opscode_authz']['source_dir']
#     repository "git@github.com:opscode/opscode-authz.git"
#     revision node['opscode_authz']['revision']
#     user node['opscode_authz']['user']

#     if File.directory?("#{node['opscode_authz']['source_dir']}/rel/authz")
#       notifes :stop, "service[opscode-authz]", :immediately
#     end

#     notifies :run, "execute[build-authz]", :immediately
#     notifies :restart, "service[opscode-authz]", :delayed
#   end
# end

# # Build the code
# execute "build-authz" do
#   command "make distclean rel"
#   cwd node['opscode_authz']['source_dir']
#   user "root"
#   group "root"
#   action :nothing
# end

# # link from build directory to
# link "link-authz" do
#   to "#{node[:opscode_authz][:build_dir]}/rel/authz"
#   target_file node[:opscode_authz][:deploy_dir]
#   owner node[:opscode_authz][:owner]
#   group node[:opscode_authz][:group]
# end

# Drop off the config files

# Add Runit

# Start the service

# Send notifications




# Separate recipes for adding GDash dashboards, setting up for a testing environment
