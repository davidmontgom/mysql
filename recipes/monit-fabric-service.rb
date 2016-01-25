service "monit"
template "/etc/monit/conf.d/monit.fabric.service.conf" do
  path "/etc/monit/conf.d/monit.fabric.service.conf"
  source "monit.fabric.service.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, resources(:service => "monit")
end