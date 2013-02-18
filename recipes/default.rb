#
# Cookbook Name:: opscode-authz
# Recipe:: default
#
# Copyright (C) 2013 Opscode
#
# All rights reserved - Do Not Redistribute

# This recipe can probably be extracted to a shared cookbook
include_recipe "opscode-authz::common_directories"

node.set['opscode-authz']['source_dir'] = if node['opscode-authz']['development_mode']
                                            # assumes running from the oc_authz repo via Vagrant
                                            "/vagrant"
                                          else
                                            "#{node['source_directory']}/oc_authz"
                                          end

include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

# The user that the Authz service will run as
group node['opscode-authz']['group']
user node['opscode-authz']['user'] do
  group node['opscode-authz']['group']
  system true
  shell "/bin/bash"
end

include_recipe "opscode-authz::fetch_code"
include_recipe "opscode-authz::database"
