include_recipe "opscode-heimdall::common_directories"
include_recipe "opscode-heimdall::erlang_application_base"

include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

include_recipe "opscode-heimdall::build"
include_recipe "opscode-heimdall::service"
