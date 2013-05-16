#
# Cookbook Name:: opscode-bifrost
# Recipe:: gdash
#
# Copyright 2013, Opscode, Inc.
#
# All rights reserved - Do not redistribute
#
# This recipe sets up dashboards for Gdash [1] to monitor various
# operational aspects of Bifrost.  It does NOT set up Gdash,
# Graphite, estatsd, or anything else; it merely creates Gdash
# dashboard files.
#
# The idea is to keep dashboards for a particular application with the
# code that deploys that application, with the assumption being that
# the developers that wrote it are the ones best suited for creating
# the dashboards that monitor it.
#
# To use this recipe as it was intended, include it in the run list of
# your Gdash server nodes. After the first CCR, make sure to restart apache
# for changes to take effect. e.g. sudo /etc/init.d/apache2 restart
# Subsequent updates normally do not require a restart.
#
# NOTE: When / if we begin using the community gdash cookbook [2], I'd
# like to use its LWRPs instead of separate template files.  That would
# simplify this recipe a great deal.
#
# [1] https://github.com/ripienaar/gdash
# [2] https://github.com/heavywater/chef-gdash
#

# TODO: I suppose this can go away when we rename to Bifrost
# officially
app_name = "bifrost"

# TODO: Clean this up when we move to community gdash
template_dir = node['gdash']['templatedir'] ||                                       # community cookbook pattern
  (node['gdash']['gdash_dir'] && "#{node['gdash']['gdash_dir']}/graph_templates") || # current Opscode cookbook pattern
  raise("Unknown template directory!")                                               # The cookbook is busted

# All our dashboards will go here; we'll define it up front for
# DRY-ness' sake.
dashboard_root = "#{template_dir}/#{app_name}"

# Scaling factor.  Some metrics are per a 10 second window, so we need
# to scale them back to give us per second metrics.
#
# TODO: It would be nice to grab this from our Graphite
# configuration, but I don't think that is currently
# exposed.
scaling_factor = (1.0 / 10)

# The community cookbook defines owner and group attributes, but our
# current Opscode gdash cookbook appears to use a hard-coded
# 'www-data'
#
# TODO: fix this when we switch to community gdash
gdash_owner = node['gdash']['owner'] || 'www-data'
gdash_group = node['gdash']['group'] || 'www-data'

# Remove all the Bifrost dashboard files that are currently on the
# machine; we only want the ones that are defined in this cookbook
directory dashboard_root do
  action :delete
  recursive true
end

################################################################################
#
# Database Dashboards
#
################################################################################

database_dashboard_name = "database"

directory "#{dashboard_root}/#{database_dashboard_name}" do
  owner gdash_owner
  group gdash_group
  recursive true
end

# Create the "overall database dashboard"

file "#{dashboard_root}/#{database_dashboard_name}/dash.yaml" do
  content """---
:name: Overall Bifrost Database
:description: Bifrost Database Call Metrics
"""
  owner gdash_owner
  group gdash_group
end

["database_overall_response_times",
 "database_requests_per_second_by_function"].each do |graph|
  template "#{dashboard_root}/#{database_dashboard_name}/#{graph}.graph" do
    variables({
                :app_name => app_name,
                :scaling_factor => scaling_factor
              })
    owner gdash_owner
    group gdash_group
  end
end

["mean", "upper", "lower", "upper_90"].each do |metric|
  template "#{dashboard_root}/#{database_dashboard_name}/database_aggregate_#{metric}.graph" do
    source "database_aggregate_metric.graph.erb"
    variables({
                :app_name => app_name,
                :metric => metric,
                :scaling_factor => scaling_factor
              })
    owner gdash_owner
    group gdash_group
  end

  template "#{dashboard_root}/#{database_dashboard_name}/database_aggregate_#{metric}_by_function.graph" do
    source "database_aggregate_metric_by_function.graph.erb"
    variables({
                :app_name => app_name,
                :metric => metric,
                :scaling_factor => scaling_factor
              })
    owner gdash_owner
    group gdash_group
  end
end

# end "overall database dashboard"

# Create dedicated dashboards for each database function

# TODO: grab the names of the database (Erlang) function calls from
# the whisper database files on disk.  This has the advantage of being
# all nice and dynamic, but has the downside of requiring metrics to
# be there first.  Running a second time would pick things up.
database_functions = ["acl_membership",
                      "add_to_group",
                      "create",
                      "create_ace",
                      "delete",
                      "delete_acl",
                      "exists",
                      "group_membership",
                      "has_permission",
                      "remove_from_group"]

database_functions.each do |database_function|

  database_function_dashboard_directory = "#{dashboard_root}/bifrost_database_#{database_function}"

  directory database_function_dashboard_directory do
    owner gdash_owner
    group gdash_group
    recursive true
  end

  file "#{database_function_dashboard_directory}/dash.yaml" do
    content """---
:name: Bifrost Database '#{database_function}' Function
:description: Metrics for 'bifrost_db:#{database_function}' Function Calls
"""
    owner gdash_owner
    group gdash_group
  end

  template "#{database_function_dashboard_directory}/#{database_function}_times.graph" do
    source "database_function_times.graph.erb"
    variables({
                :app_name => app_name,
                :database_function => database_function,
                :scaling_factor => scaling_factor
              })
    owner gdash_owner
    group gdash_group
  end

  template "#{database_function_dashboard_directory}/#{database_function}_counts_per_second.graph" do
    source "database_function_counts_per_second.graph.erb"
    variables({
                :app_name => app_name,
                :database_function => database_function,
                :scaling_factor => scaling_factor
              })
    owner gdash_owner
    group gdash_group
  end
end # database function-specific dashboards


################################################################################
#
# HTTP API Dashboards
#
################################################################################

http_dashboard_name = "http"

directory "#{dashboard_root}/#{http_dashboard_name}" do
  owner gdash_owner
  group gdash_group
  recursive true
end

# Create the "overall http dashboard"

file "#{dashboard_root}/#{http_dashboard_name}/dash.yaml" do
  content """---
:name: Overall Bifrost REST API
:description: HTTP Metrics
"""
  owner gdash_owner
  group gdash_group
end

["http_requests_per_second",
 "http_requests_per_second_by_request_type",
 "http_requests_per_second_by_status_code"].each do |graph|
  template "#{dashboard_root}/#{http_dashboard_name}/#{graph}.graph" do
    variables({
                :app_name => app_name,
                :scaling_factor => scaling_factor
              })
    owner gdash_owner
    group gdash_group
  end
end

{"most" => "{lower,mean,upper_90}", "upper" => "upper"}.each do |label, metrics|
  template "#{dashboard_root}/#{http_dashboard_name}/http_overall_response_times_#{label}.graph" do
    source "http_overall_response_times.graph.erb"
    variables({
                :app_name => app_name,
                :scaling_factor => scaling_factor,
                :metrics => metrics
              })
    owner gdash_owner
    group gdash_group
  end
end

# end "overall http dashboard"

# Create dedicated dashboards for each request type

# TODO: grab the names of the "types" from the whisper database files
# on disk.  This has the advantage of being all nice and dynamic, but
# has the downside of requiring metrics to be there first.  Running a
# second time would pick things up.
request_types = ["actor",
                 "container",
                 "group",
                 "object"]

request_types.each do |request_type|
  request_type_dashboard_directory = "#{dashboard_root}/bifrost_http_#{request_type}"

  # Make sure there's a place to stick the dashboards
  directory request_type_dashboard_directory do
    owner gdash_owner
    group gdash_group
    recursive true
  end

  # Create the dashboard file
  file "#{request_type_dashboard_directory}/dash.yaml" do
    content """---
:name: Bifrost API '#{request_type}' Request Type
:description: HTTP Metrics for '#{request_type}' Requests
"""
    owner gdash_owner
    group gdash_group
  end

  # Create a graph showing all the lower, mean, upper 90%, and upper
  # response times for every combination of request type and HTTP verb
  ["DELETE", "GET", "POST", "PUT"].each do |verb|
    template "#{request_type_dashboard_directory}/#{request_type}_#{verb.downcase}_times.graph" do
      source "http_request_type_verb_times.graph.erb"
      variables({
                  :app_name => app_name,
                  :request_type => request_type,
                  :verb => verb
                })
      owner gdash_owner
      group gdash_group
    end
  end

  template "#{request_type_dashboard_directory}/#{request_type}_counts_per_second.graph" do
    source "http_request_type_counts_per_second.graph.erb"
    variables({
                :app_name => app_name,
                :request_type => request_type,
                :scaling_factor => scaling_factor
              })
    owner gdash_owner
    group gdash_group
  end

  # TODO: It would be nice to also break things out and see the requests
  # for each request type by HTTP status code, but our metrics are not
  # currently structured to allow us to do that.

end
