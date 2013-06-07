# OTP release artifact LWRP provider. Builds or retrieves a release artifact.

action :create do
  opts = options(new_resource)

  if opts[:development_mode]
    # In dev we build from source. Source can be a local
    # directory, e.g. "/vagrant", or a git repo.
    # Generates a tar ball appname-revision.tgz and puts
    # it in dest_dir.
    Chef::Log.info("*** In development mode, build #{opts[:tarball]} from #{opts[:source]}.")
    opscode_bifrost_otp_build opts[:name] do
      action :build
      tarball opts[:tarball]
      source opts[:source]
      revision opts[:revision]
      force_clean_src opts[:force_clean_src]
      owner opts[:owner]
      group opts[:group]
      src_root_dir opts[:src_root_dir]
    end
  else
    # Otherwise we deploy from artifact.
    Chef::Log.info("*** Getting #{opts[:name]}-#{opts[:revision]} OTP release artifact from S3.")
    opscode_bifrost_s3_artifact opts[:name] do
      action :sync
      revision opts[:revision]
      tarball opts[:tarball]
      owner opts[:owner]
      group opts[:group]
      aws_bucket opts[:aws_bucket]
      aws_access_key_id opts[:aws_access_key_id]
      aws_secret_access_key opts[:aws_secret_access_key]
    end
  end
end

def options(r)
    service = r.name
    opts = r.to_hash

    defaults = {
        :source => node[service]['source'],
        :development_mode => node[service]['development_mode'],
        :owner => node[service]['owner'],
        :group => node[service]['group'],
        :revision => node[service]['revision'],
        :aws_bucket => node[service]['aws_bucket'],
        :aws_access_key_id => node[service]['aws_access_key_id'],
        :aws_secret_access_key => node[service]['aws_secret_access_key']
    }

    defaults.each do |k, v|
        opts[k] = v unless opts[k]
    end

    opts
end
