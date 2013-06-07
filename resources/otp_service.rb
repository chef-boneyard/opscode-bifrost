# OTP service LWRP

def initialize(*args)
  super
  @action = :deploy # default
  @run_context.include_recipe "erlang_binary::default"
end

actions :deploy, :delayed_restart, :immediate_restart, :stop, :start

# App name used to derive standard values.
attribute :name, :kind_of => String, :name_attribute => true
attribute :revision, :kind_of => String
attribute :tarball, :kind_of => String

# Force deployment.
# Normally the deploy occurs only if the revision has not been
# deployed yet. Set this to true to force re-deploying on top
# of an existing deploy.
attribute :force_deploy, :kind_of => [TrueClass, FalseClass], :default => false

# Root of /srv tree, not app-specific.
attribute :root_dir, :kind_of => String

# Location of etc dir (linked inside release).
attribute :etc_dir, :kind_of => String

# Location of log dir (linked inside release).
attribute :log_dir, :kind_of => String

# Logging options
attribute :console_log_count, :kind_of => Integer
attribute :console_log_mb, :kind_of => Integer
attribute :error_log_count, :kind_of => Integer
attribute :error_log_mb, :kind_of => Integer

# User and group that own the files.
attribute :owner, :kind_of => String
attribute :group, :kind_of => String

# For hipchat notifications:
attribute :estatsd_host, :kind_of => String
attribute :hipchat_key, :kind_of => String
attribute :app_environment, :kind_of => String, :default => node[:app_environment]

# Set to force removing the existing src dir if it exists.
# This is handy to force a build from scratch when using git.
# Careful! Don't delete your WIP source!
attribute :force_clean_src, :kind_of => [TrueClass, FalseClass], :default => false
