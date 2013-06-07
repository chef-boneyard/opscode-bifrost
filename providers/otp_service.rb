# OTP service LWRP provider. Handles generic OTP service logic:
# - get app bits: in dev mode, build from source; otherwise, get
#   artifact from S3.
# - deploy build
# - configure service
#
# Relies on node[app_name] attributes for defaults:
# - root_dir (i.e. /srv)
# - revision (git branch/sha/tag when deploying from source;
#   build artifact revision otherwise)
#
# To build from source:
# - development_mode - true means build from source
# - source - a local directory or git repo
#
# To get build from S3:
# - aws_bucket
# - aws_access_key_id
# - aws_secret_access_key
#
# For deployment notifications:
# - estatsd_host
# - hipchat_key
#
# Directories to link into release:
# - etc_dir
# - log_dir
#
# These directories get linked into release so the files
# in there don't get deleted at deploy time.
#
# Logging options:
# - console_log_count: how many console.log files to keep.
# - console_log_mb: size when log file should be rotated.
# - error_log_count: how many error.log files to keep.
# - error_log_mb: size when log file should be rotated.
#
# File ownership:
# - owner
# - group
#
# And on node itself:
# - app_environment
#

action :deploy do
    opts = options(new_resource)
    service_name = opts[:name]
    root_dir = opts[:root_dir]
    revision = opts[:revision]
    tarballs_dir = "#{root_dir}/_tarballs"
    tarball = "#{tarballs_dir}/#{service_name}-#{revision}.tgz"
    src_root_dir = "#{root_dir}/src"

    # Get app bits to a local tarball.
    # Builds from source in dev mode, otherwise retrieves from S3.
    opscode_bifrost_otp_release_artifact opts[:name] do
      tarball tarball
      development_mode opts[:development_mode]
      source opts[:source]
      revision opts[:revision]
      force_clean_src opts[:force_clean_src]
      aws_bucket opts[:aws_bucket]
      aws_access_key_id opts[:aws_access_key_id]
      aws_secret_access_key opts[:aws_secret_access_key]
      owner opts[:owner]
      group opts[:group]
      src_root_dir src_root_dir
    end

    # We have a tarball. Now deploy it.
    # (Includes hipchat notification.)
    opscode_bifrost_service_pkg opts[:name] do
      action :deploy
      revision opts[:revision]
      tarball tarball
      root_dir opts[:root_dir]
      force_deploy opts[:force_deploy] || opts[:development_mode]
      app_environment opts[:app_environment]
      estatsd_host opts[:estatsd_host]
      hipchat_key opts[:hipchat_key]
      # This doesn't seem to work... if just switching versions and the link
      # is updated, there is no notification...??
      notifies :delayed_restart, "opscode-bifrost_otp_service[#{opts[:name]}]", :immediately
    end

    # Configure
    opscode_bifrost_otp_service_config opts[:name] do
      action :create
      revision opts[:revision]
      root_dir opts[:root_dir]
      etc_dir opts[:etc_dir]
      log_dir opts[:log_dir]
      owner opts[:owner]
      group opts[:group]
      console_log_count opts[:console_log_count]
      console_log_mb opts[:console_log_mb]
      error_log_count opts[:error_log_count]
      error_log_mb opts[:error_log_mb]
    end
end

action :delayed_restart do
    service_action(:restart, :delayed)
end

action :immediate_restart do
    service_action(:restart, :immediately)
end

action :stop do
    service_action(:stop, :immediately)
end

action :start do
    service_action(:start, :immediately)
end

def service_action(requested_action, requested_timing)
    service_name = new_resource.name
    # This is the simplest way to notify another resource...?
    # A bit convoluted...
    ruby_block "#{requested_action}_#{service_name}" do
        action :create
        block do
            Chef::Log.info("*** otp_service notify #{requested_action}, service[#{service_name}], #{requested_timing}...")
        end
        notifies requested_action, "service[#{service_name}]", requested_timing
    end
end

def options(r)
    service = r.name
    opts = r.to_hash

    defaults = {
        :app_environment => node['app_environment'],
        :revision => node[service]['revision'],
        :source => node[service]['source'],
        :development_mode => node[service]['development_mode'],
        :aws_bucket => node[service]['aws_bucket'],
        :aws_access_key_id => node[service]['aws_access_key_id'],
        :aws_secret_access_key => node[service]['aws_secret_access_key'],
        :root_dir => node[service]['srv_dir'],
        :estatsd_host => node[service]['estatsd_host'],
        :hipchat_key => node[service]['hipchat_key'],
        :etc_dir => node[service]['etc_dir'],
        :log_dir => node[service]['log_dir'],
        :console_log_count => node[service]['console_log_count'],
        :console_log_mb => node[service]['console_log_mb'],
        :error_log_count => node[service]['error_log_count'],
        :error_log_mb => node[service]['error_log_mb'],
        :owner => node[service]['owner'],
        :group => node[service]['group']
    }

    defaults.each do |k, v|
        opts[k] = v unless opts[k]
    end

    opts
end
