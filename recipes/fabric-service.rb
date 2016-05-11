


easy_install_package "dnspython" do
  action :install
end

easy_install_package "boto" do
  action :install
end

package "libffi-dev" do
  action :install
end

package "libssl-dev" do
  action :install
end

easy_install_package "paramiko" do
  options "-U"
  action :install
end


execute "restart_fabric_service" do
  command "sudo supervisorctl restart fabric_service_server:"
  action :nothing
end

cookbook_file "/var/fabric_add_servers_monitor.py" do
  source "fabric_add_servers_monitor.py"
  mode 00744
  notifies :run, "execute[restart_fabric_service]"
  #notifies :restart, resources(:service => "supervisord")
end


template "/etc/supervisor/conf.d/supervisord.fabric.service.include.conf" do
  path "/etc/supervisor/conf.d/supervisord.fabric.service.include.conf"
  source "supervisord.fabric.service.include.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, resources(:service => "supervisord"), :immediately 
end
service "supervisord"

