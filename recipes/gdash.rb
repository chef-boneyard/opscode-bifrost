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

# TODO: Currently our storage directory is hard-coded in the
# graphite/templates/default/carbon.conf.erb template.  The Community
# cookbook from Heavywater (https://github.com/hw-cookbooks/graphite)
# uses an attribute, though (for at least part of the path in
# question).
#
# We'll rely on an attribute (that we don't set in our infrastructure
# just yet) and fall back to what our current directory is.  That
# should make this pretty future-proof.
graphite_storage_dir = node['graphite']['storage_dir'] || "/opt/graphite/storage"
whisper_dir = "#{graphite_storage_dir}/whisper"

# All our dashboards will go here; we'll define it up front for
# DRY-ness' sake.
dashboard_root = "#{template_dir}/#{app_name}"

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
                :app_name => app_name
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
                :metric => metric
              })
    owner gdash_owner
    group gdash_group
  end

  template "#{dashboard_root}/#{database_dashboard_name}/database_aggregate_#{metric}_by_function.graph" do
    source "database_aggregate_metric_by_function.graph.erb"
    variables({
                :app_name => app_name,
                :metric => metric
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
                :database_function => database_function
              })
    owner gdash_owner
    group gdash_group
  end

  template "#{database_function_dashboard_directory}/#{database_function}_counts_per_second.graph" do
    source "database_function_counts_per_second.graph.erb"
    variables({
                :app_name => app_name,
                :database_function => database_function
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
 "http_requests_per_second_by_module",
 "http_requests_per_second_by_status_code"].each do |graph|
  template "#{dashboard_root}/#{http_dashboard_name}/#{graph}.graph" do
    variables({
                :app_name => app_name
              })
    owner gdash_owner
    group gdash_group
  end
end

# Here we display lower, mean, and upper_90 response time metrics on
# one graph.  We don't add 'upper' because it currently swamps the
# rest of them, making a graph with all of them borderline useless.
template "#{dashboard_root}/#{http_dashboard_name}/http_overall_response_times.graph" do
  variables({
              :app_name => app_name,
              :metrics => "{lower,mean,upper_90}"
            })
  owner gdash_owner
  group gdash_group
end

# Individual lower, mean, upper_XX, upper graphs.  Having them all on
# the same graph can be problematic if one (say, 'upper') completely
# drowns out all the others.
["lower", "mean", "upper_90", "upper"].each do |metric|
  template "#{dashboard_root}/#{http_dashboard_name}/http_#{metric}_response_times.graph" do
    source "http_individual_metric_response_times.graph.erb"
    variables({
                :app_name => app_name,
                :metric => metric
              })
    owner gdash_owner
    group gdash_group
  end
end

# end "overall http dashboard"

# Create dedicated dashboards for each request type

# The metrics have a structure like this:
#
#   stats.bifrost.application.byRequestType.MODULE_NAME.ENTITY_TYPE.etc...
#
# We can grab the list of modules dynamically by querying the Whisper
# DB files on disk, instead of hard-coding them here.
modules = Bifrost::WhisperDB.next_level_metrics("stats.#{app_name}.application.byRequestType",
                                                whisper_dir)
modules.each do |mod|
  request_type_dashboard_directory = "#{dashboard_root}/bifrost_http_#{mod}"

  # Make sure there's a place to stick the dashboards
  directory request_type_dashboard_directory do
    owner gdash_owner
    group gdash_group
    recursive true
  end

  # Create the dashboard file
  file "#{request_type_dashboard_directory}/dash.yaml" do
    content """---
:name: Bifrost API '#{mod}' Module
:description: HTTP Metrics for Requests handled by #{mod}
"""
    owner gdash_owner
    group gdash_group
  end

  template "#{request_type_dashboard_directory}/#{mod}_counts_per_second.graph" do
    source "http_request_module_counts_per_second.graph.erb"
    variables({
                :app_name => app_name,
                :module => mod
              })
    owner gdash_owner
    group gdash_group
  end

  # Each module handles a subset of all auth entity types ("actor",
  # "container", "group", "object"); some handle all, while others
  # handle fewer.
  #
  # The current metric setup places these entity types after the
  # module in the metric path.  We'll take a look at the whisper files
  # on disk to determine which entity types are valid for the current
  # module.
  #
  # This does require that the whisper files exist on disk, so it may
  # require a second chef-client run after metrics start flowing
  # before the proper graphs show up.
  entity_types = Bifrost::WhisperDB.next_level_metrics("stats.timers.#{app_name}.application.byRequestType.#{mod}",
                                                        whisper_dir)
  entity_types.each do |entity_type|

    # Only show a graph for HTTP verbs where there
    # have been more than `threshold` events in the
    # time period
    http_method_count_threshold = 1

    template "#{request_type_dashboard_directory}/#{mod}_#{entity_type}_verb_counts_per_second.graph" do
      source "http_request_module_type_verb_counts_per_second.graph.erb"
      variables({
                  :app_name => app_name,
                  :module => mod,
                  :entity_type => entity_type,
                  :threshold => http_method_count_threshold
                })
      owner gdash_owner
      group gdash_group
    end

    # TODO: tweak the library methods to be able to pull these out too?
    ["lower", "mean", "upper_90", "upper"].each do |metric|

      template "#{request_type_dashboard_directory}/#{mod}_#{entity_type}_verb_#{metric}.graph" do
        source "http_request_module_type_verb_metric.graph.erb"
        variables({
                    :app_name => app_name,
                    :module => mod,
                    :entity_type => entity_type,
                    :metric => metric,
                    :threshold => http_method_count_threshold
                  })
        owner gdash_owner
        group gdash_group
      end
    end

  end
  # TODO: It would be nice to also break things out and see the requests
  # for each request type by HTTP status code, but our metrics are not
  # currently structured to allow us to do that.

end

################################

# Machine-based Graphs
bifrost_hosts = partial_search(:node, "chef_environment:#{node.chef_environment} AND role:opscode-bifrost",
                               {"hostname" => ["hostname"]})

# Our Munin clients have different hostnames in preprod (EC2)
# vs. prod.  We get our system metrics from munin, so this affects the
# metric labels we need to use.
#
# See cookbooks/munin/templates/default/munin-node.conf.erb for
# why this is necessary.
#
# These prefixes are presented already in reverse-DNS style, which is
# how we structure our metrics hierarchy.
#
# As coded, this case statement assumes that the machine this recipe
# is running on (the GDash server) is in the same app_environment as
# the bifrost hosts.  Probably a sane assumption, but being explicit
# never hurts.
server_metric_prefix = case node.chef_environment
                       when "rs-preprod"
                         "internal.ec2"
                       else
                         "us.opscode"
                       end

bifrost_hosts.each do |host|
  hostname = host["hostname"]

  dashboard_directory = "#{dashboard_root}/#{hostname}"

  directory dashboard_directory do
    owner gdash_owner
    group gdash_group
    recursive true
  end

  file "#{dashboard_directory}/dash.yaml" do
    content """---
:name: Information for #{hostname}
:description: Machine-specific Metrics for #{hostname}
"""
    owner gdash_owner
    group gdash_group
  end

  template "#{dashboard_directory}/#{hostname}_network_traffic.graph" do
    source "machine_network_traffic.graph.erb"
    variables({
                :machine => hostname,
                :prefix => server_metric_prefix,
                :app_name => app_name
              })
    owner gdash_owner
    group gdash_group
  end

  template "#{dashboard_directory}/#{hostname}_cpu_vs_response_time.graph" do
    source "cpu_vs_response_time.graph.erb"
    variables({
                :machine => hostname,
                :prefix => server_metric_prefix,
                :app_name => app_name
              })
    owner gdash_owner
    group gdash_group
  end

  template "#{dashboard_directory}/#{hostname}_cpu_vs_requests_per_second.graph" do
    source "cpu_vs_requests_per_second.graph.erb"
    variables({
                :machine => hostname,
                :prefix => server_metric_prefix,
                :app_name => app_name
              })
    owner gdash_owner
    group gdash_group
  end

end
