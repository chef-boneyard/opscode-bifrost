opscode_pedant "oc-authz-pedant" do
  revision node['oc-authz-pedant']['revision']
  variables({
              :host => node['oc_bifrost']['host'],
              :port => node['oc_bifrost']['port']
            })
end
