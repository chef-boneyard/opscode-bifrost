# Deploy app from artifact
app_name = node['app_name']

# Artifacts get extracted under /srv/<app>_releases/<revision>
# Then the deployed artifact is linked at /srv/<app>

srv_dir = '/srv'
releases_dir = "#{srv_dir}/#{app_name}_releases"

directory releases_dir do
  owner "opscode"
  group "opscode"
  mode "0755"
  recursive true
end

revision = node[app_name]['build-revision']
tarball_name = "#{revision}.tar.gz"
platform = "#{node['platform']}-#{node['platform_version']}"
arch = node['kernel']['machine']
object_name = "artifacts/#{platform}/#{arch}/#{app_name}/#{tarball_name}"
bucket_name = "opscode-ci"
dest_dir = "#{releases_dir}/#{revision}"
artifact_aws = data_bag_item("aws", "rs-preprod")

opscode_extensions_s3_tarball app_name do
  destination dest_dir
  user "opscode"
  group "opscode"
  mode "644"
  revision revision || (raise "missing revision")
  aws_access_key_id artifact_aws['aws_access_key_id']
  aws_secret_access_key artifact_aws['aws_secret_access_key']
  bucket bucket_name
  object object_name
  seconds_to_expire 120
  # we could probably improve this, but for now this is safest as it
  # ensures we stop the running service before switching the symlink
  # of current.
  notifies :stop, "service[#{app_name}]", :immediately
  not_if "test -d #{dest_dir}"
end

link "link-current" do
  to dest_dir
  target_file "#{srv_dir}/#{app_name}"
  owner "opscode"
  group "opscode"
end

deployment_notification("opscode_extensions_s3_tarball[#{app_name}]") do
  app_environment node.chef_environment
  service_name app_name
  estatsd_host data_bag_item("vips", node.chef_environment)["estatsd_host"]
  hipchat_key data_bag_item("environments", node.chef_environment)["hipchat_key"]
end
