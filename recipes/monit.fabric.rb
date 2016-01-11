service "monit"
template "/etc/monit/conf.d/fabric.conf" do
  path "/etc/monit/conf.d/fabric.conf"
  source "monit.fabric.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, resources(:service => "monit")
end