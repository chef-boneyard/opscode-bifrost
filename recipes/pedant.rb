opscode_pedant "oc-authz-pedant" do
  revision node['oc-authz-pedant']['revision']
  variables({
              :host => node['oc_heimdall']['host'],
              :port => node['oc_heimdall']['port']
            })
end
