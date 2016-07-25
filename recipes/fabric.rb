server_type = node.name.split('-')[0]
slug = node.name.split('-')[1] 
datacenter = node.name.split('-')[2]
environment = node.name.split('-')[3]
location = node.name.split('-')[4]
cluster_slug = File.read("/var/cluster_slug.txt")
cluster_slug = cluster_slug.gsub(/\n/, "") 

data_bag("server_data_bag")
fabric_server = data_bag_item("server_data_bag", server_type)
password = fabric_server[datacenter][environment][location][cluster_slug]['meta']['password']


#http://dev.mysql.com/doc/mysql-utilities/1.5/en/fabric.html
bash "install_fabric_user" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
  
    echo "CREATE USER 'fabric_store'@'%' IDENTIFIED BY 'Test101';" | mysql -u root -pTest101
    echo "GRANT ALTER, CREATE, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, SELECT, UPDATE ON mysql_fabric.* TO 'fabric_store'@'%';" | mysql -u root -pTest101
    echo "FLUSH PRIVILEGES;" | mysql -u root -pTest101
    
    touch #{Chef::Config[:file_cache_path]}/fabric_user_store.lock
EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/fabric_user_store.lock")}
end

remote_file "#{Chef::Config[:file_cache_path]}/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb" do
    source "http://dev.mysql.com/get/Downloads/Connector-Python/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb"
    action :create_if_missing
end

remote_file "#{Chef::Config[:file_cache_path]}/mysql-utilities_1.5.6-1ubuntu14.04_all.deb" do
    source "http://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-utilities_1.5.6-1ubuntu14.04_all.deb"
    action :create_if_missing
end

dpkg_package "#{Chef::Config[:file_cache_path]}/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb" do
  action :install
end

dpkg_package "#{Chef::Config[:file_cache_path]}/mysql-utilities_1.5.6-1ubuntu14.04_all.deb" do
  action :install
end

directory "/usr/share/pyshared/mysql" do
  mode "0666"
  recursive true
  action :create
end


template "/etc/mysql/fabric.cfg" do
  path "/etc/mysql/fabric.cfg"
  source "fabric.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
  #notifies :start, resources(:service => "mysql")
  variables :password => "#{password}"
end



bash "init_fabric" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    mysqlfabric manage setup --param=storage.user=fabric
    mysqlfabric manage start --daemon
    touch #{Chef::Config[:file_cache_path]}/fabric_init.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/fabric_init.lock")}
end





=begin
execute "restart_supervisorctl_fabric" do
  command "mysqlfabric manage stop;supervisorctl restart fabric_server:"
  action :nothing
end

template "/etc/supervisor/conf.d/fabric.conf" do
  path "/etc/supervisor/conf.d/fabric.conf"
  source "supervisord.fabric.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  #notifies :restart, resources(:service => "supervisord")
  notifies :run, "execute[restart_supervisorctl_fabric]"
end
=end

=begin

For app servers use python connector to connect to fabric servers
For Druid create primary DNS
write script that will create primary DNS with current 
if primary fails then do update the primary DNS with new primary ip address

Fabric will be manually maitained


n

https://dev.mysql.com/doc/mysql-utilities/1.5/en/connector-python-fabric.html
http://dev.mysql.com/doc/mysql-utilities/1.5/en/fabric-faq.html
https://blogs.oracle.com/jbalint/entry/accessing_fabric_ha_groups_from
https://dev.mysql.com/tech-resources/articles/mysql-fabric-ga.html
mysqlfabric manage setup --param=storage.user=fabric
mysqlfabric group create druid
mysqlfabric group add druid 198.211.97.48:3306
mysqlfabric group promote druid
mysqlfabric group health druid
mysqlfabric group lookup_servers druid



#http://dev.mysql.com/doc/mysql-utilities/1.5/en/fabric-quick-start-replication.html
mysqlfabric manage start   --daemonize --config=/var/fabric.conf
mysqlfabric manage stop

mysqlfabric group create my_group
mysqlfabric group add my_group localhost:3307
mysqlfabric group add my_group localhost:3308
mysqlfabric group add my_group localhost:3309

mysqlfabric group lookup_servers my_group
mysqlfabric group health my_group
=end








