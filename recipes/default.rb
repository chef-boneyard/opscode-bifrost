#
# Cookbook Name:: opscode-heimdall
# Recipe:: default
#
# Copyright (C) 2013 Opscode
#
# All rights reserved - Do Not Redistribute

# This recipe can probably be extracted to a shared cookbook
include_recipe "opscode-heimdall::common_directories"

# TODO: This could be a recipe in our erlang cookbook
include_recipe "opscode-heimdall::erlang_application_base"

include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

include_recipe "opscode-heimdall::build"
include_recipe "opscode-heimdall::database"
include_recipe "opscode-heimdall::service"
