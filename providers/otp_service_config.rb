# OTP service config LWRP provider. Configures a generic OTP app.
# - etc, log directories linked into app.
# - vm.args, nodetool, erl, start script
# - logrotate (console.log and error.log)
# - rsyslog
# - runit_service

action :create do
    std_directory new_resource.etc_dir
    std_directory new_resource.log_dir
    std_directory "#{new_resource.log_dir}/sasl"
    in_app_link new_resource.etc_dir, "etc"
    in_app_link new_resource.log_dir, "log"

    template "#{new_resource.etc_dir}/vm.args" do
        source "vm.args.erb"
        owner new_resource.owner
        group new_resource.group
        mode 0644
        variables(:app_name => new_resource.name)
        notifies :restart, "service[#{service_name}]", :delayed
    end

    # This is the script that will actually run the application.  It is
    # enhanced from the standard Erlang release boot script in that it has
    # support for running under runit.
    std_directory "#{target_dir}/bin"
    template "#{target_dir}/bin/#{new_resource.name}" do
        source "run_script.sh.erb"
        owner new_resource.owner
        group new_resource.group
        mode 0755
        variables(:log_dir => new_resource.log_dir)
        notifies :restart, "service[#{service_name}]", :delayed
    end

    # These are some stock scripts that the boot script needs to call.
    ["nodetool", "erl"].each do |file|
        cookbook_file "#{target_dir}/bin/#{file}" do
            owner new_resource.owner
            group new_resource.group
            mode 0755
        end
    end

    template "/etc/logrotate.d/#{new_resource.name}" do
      source 'logrotate.erb'
      owner 'root'
      group 'root'
      mode '644'
      variables({
                  :console_log_count => new_resource.console_log_count,
                  :console_log_mb  => new_resource.console_log_mb,
                  :error_log_count   => new_resource.error_log_count,
                  :error_log_mb    => new_resource.error_log_mb,
                  :log_dir           => new_resource.log_dir,
                })
    end

    # Bifrost is chatty, so we'll want to be a bit more aggressive running
    # logrotate to ensure that log sizes don't get too big.
    template "/etc/cron.hourly/logrotate" do
      cookbook "logrotate"
      owner "root"
      group "root"
      mode "755"
    end

    # Drop off an rsyslog configuration
    template "/etc/rsyslog.d/30-#{name}.conf" do
      source "erlang_app_rsyslog.conf.erb"
      owner "root"
      group "root"
      mode 0644
      variables(:app_name => new_resource.name,
                :log_file_path => "/var/log/#{name}.log")
      notifies :restart, "service[rsyslog]"
    end

    service_opts = {
        :srv_dir => target_dir,
        :bin_name => name,
        :app_name => name,

        # These are for the run script
        :run_setuidgid => owner,
        :run_envuidgid => group,

        # This is for the log-run script
        :log_setuidgid => "nobody"
    }
    runit_service service_name do
        template_name "erlang_app" # Our common template
                                   # resolves to our sv-erlang_app-run.erb
                                   # and sv-erlang_app-log-run.erb
        options service_opts
    end
end

def std_directory(dir)
    directory dir do
        owner new_resource.owner
        group new_resource.group
        mode 0755
        recursive true
    end
end

def in_app_link(source, destination)
    target_file = "#{target_dir}/#{destination}"

    # Sometimes build tarball has these as directories.
    execute "otp_app_#{name}_cleanup_#{destination}" do
        command "rm -Rf #{target_file}"
        only_if "test -d #{target_file}"
    end

    link destination do
        to source
        target_file target_file
        owner new_resource.owner
        group new_resource.group
    end
end

def name
    new_resource.name
end

def revision
    new_resource.revision
end

def owner
    new_resource.owner
end

def group
    new_resource.group
end

def target_dir
    "#{app_releases_dir}/#{revision}/#{name}"
end

def app_releases_dir
    "#{releases_dir}/#{name}"
end

def releases_dir
    "#{new_resource.root_dir}/_releases"
end

def service_name
    new_resource.name
end
