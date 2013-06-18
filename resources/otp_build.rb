# OTP build LWRP. Generates a tarball from source.

def initialize(*args)
  super
  @action = :build

  @run_context.include_recipe "erlang_binary::default"
  @run_context.include_recipe "erlang_binary::rebar"
  @run_context.include_recipe "git"
end

actions :build, :default => :build

# App name
attribute :name, :kind_of => String, :name_attribute => true

# Source can be a local dir or a git repo.
attribute :source, :kind_of => String, :required
attribute :revision, :kind_of => String, :required

# The resulting tarball.
attribute :tarball, :kind_of => String, :required

# Set to force removing the existing src dir if it exists.
attribute :force_clean_src, :kind_of => [TrueClass, FalseClass], :default => false

# File ownership and permissions
attribute :owner, :kind_of => String, :required
attribute :group, :kind_of => String, :required
attribute :dir_mode, :kind_of => String, :default => "0755"
attribute :file_mode, :kind_of => String, :default => "0644"

# Optionally override where source goes when using git.
attribute :src_root_dir, :kind_of => String, :default => "/usr/local/src"
