include_recipe "git"
include_recipe "runit"

include_recipe "opscode-bifrost::common_directories"
include_recipe "opscode-bifrost::erlang_application_base"

include_recipe "erlang_binary::default"
include_recipe "erlang_binary::rebar"

include_recipe "opscode-bifrost::build"
include_recipe "opscode-bifrost::service"
