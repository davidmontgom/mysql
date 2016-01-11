


service "monit"

template "/etc/monit/conf.d/mysql.conf" do
  path "/etc/monit/conf.d/mysql.conf"
  source "monit.mysql.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, resources(:service => "monit")
end