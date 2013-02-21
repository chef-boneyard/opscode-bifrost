#
# Cookbook Name:: opscode-heimdall
# Recipe:: default
#
# Copyright (C) 2013 Opscode
#
# All rights reserved - Do Not Redistribute

# This recipe can probably be extracted to a shared cookbook
include_recipe "opscode-heimdall::common_directories"

node.set['oc_heimdall']['source_dir'] = if node['oc_heimdall']['development_mode']
                                            # assumes running from the oc_heimdall repo via Vagrant
                                            "/vagrant"
                                          else
                                            "#{node['source_directory']}/oc_heimdall"
                                          end

include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

# The user that the Authz service will run as
group node['oc_heimdall']['group']
user node['oc_heimdall']['user'] do
  group node['oc_heimdall']['group']
  system true
  shell "/bin/bash"
end

include_recipe "opscode-heimdall::fetch_code"
include_recipe "opscode-heimdall::database"
