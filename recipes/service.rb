include_recipe "runit"
runit_service 'oc_bifrost' do
  template_name "erlang_app" # Our common template
  options({
            :srv_dir => node['oc_bifrost']['srv_dir'],
            :bin_name => 'oc_bifrost',

            # See http://smarden.org/runit/chpst.8.html

            # These are for the run script
            :run_setuidgid => "opscode",
            :run_envuidgid => "opscode",

            # This is for the log-run script
            :log_setuidgid => "nobody"
          })
end
