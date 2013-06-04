app_name = node['app_name']

include_recipe "logrotate::default"

include_recipe "opscode-bifrost::common_directories"
include_recipe "opscode-bifrost::erlang_application_base"

include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

if node[app_name]['development_mode']
  # In dev we build from source
  include_recipe "opscode-bifrost::build"
else
  # Otherwise we deploy from artifact
  include_recipe "opscode-bifrost::deploy"
end

include_recipe "opscode-bifrost::service"
