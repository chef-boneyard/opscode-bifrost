env = data_bag_item("environments", node.app_environment)

#
# Stop opscode-authz service
# 
%w(/srv/opscode-authz-build /var/log/opscode-authz /srv/opscode-authz).each do |dir|
  directory dir do
    recursive true
    action :delete
  end
end

file "/etc/rsyslog.d/30-opscode-authz.conf" do
  action :delete
end

file "/etc/cron.daily/authz-access-log-cleanup" do
  action :delete
end

runit_service 'opscode-authz' do
  action :delete
end

munin_plugin "port_" do
  plugin "port_#{env['opscode_authz_port']}"
  action :delete
end
