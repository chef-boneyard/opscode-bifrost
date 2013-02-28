app_name = node['app_name']

include_recipe "runit"
runit_service app_name do
  template_name "erlang_app" # Our common template
  options({
            :srv_dir => node[app_name]['srv_dir'],
            :bin_name => app_name,
            :app_name => app_name,

            # See http://smarden.org/runit/chpst.8.html

            # These are for the run script
            :run_setuidgid => "opscode",
            :run_envuidgid => "opscode",

            # This is for the log-run script
            :log_setuidgid => "nobody"
          })
end
