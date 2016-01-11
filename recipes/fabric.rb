datacenter = node.name.split('-')[0]
environment = node.name.split('-')[1]
location = node.name.split('-')[2]
server_type = node.name.split('-')[3]
slug = node.name.split('-')[4] 
cluster_slug = File.read("/var/cluster_slug.txt")
cluster_slug = cluster_slug.gsub(/\n/, "") 

data_bag("server_data_bag")
mysql_server = data_bag_item("server_data_bag", server_type)
password = mysql_server[datacenter][environment][location][cluster_slug]['meta']['password']

#http://dev.mysql.com/doc/mysql-utilities/1.5/en/fabric.html

bash "install_fabric" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    sudo mkdir -p /usr/share/pyshared/mysql
    wget http://dev.mysql.com/get/Downloads/Connector-Python/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb
    dpkg -i mysql-connector-python_2.1.3-1ubuntu14.04_all.deb
    wget http://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-utilities_1.5.6-1ubuntu14.04_all.deb
    dpkg -i mysql-utilities_1.5.6-1ubuntu14.04_all.deb
    touch #{Chef::Config[:file_cache_path]}/fabric.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/fabric.lock")}
end


bash "install_fabric" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
  
    echo "CREATE USER 'fabric_store'@'%' IDENTIFIED BY 'Test101';" | mysql -u root -pTest101
    echo "GRANT ALTER, CREATE, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, SELECT, UPDATE ON mysql_fabric.* TO 'fabric_store'@'%';" | mysql -u root -pTest101
    echo "FLUSH PRIVILEGES;" | mysql -u root -pTest101
    
    echo "CREATE USER 'fabric_server'@'%' IDENTIFIED BY 'Test101';" | mysql -u root -pTest101
    echo "GRANT DELETE, PROCESS, RELOAD, REPLICATION CLIENT, REPLICATION SLAVE, SELECT, SUPER, TRIGGER ON *.* TO 'fabric_server'@'%';" | mysql -u root -pTest101
    echo "GRANT ALTER, CREATE, DELETE, DROP, INSERT, SELECT, UPDATE ON mysql_fabric.* TO 'fabric_server'@'%';" | mysql -u root -pTest101
    echo "FLUSH PRIVILEGES;" | mysql -u root -pTest101 
    
    echo "CREATE USER 'fabric_restore'@'%' IDENTIFIED BY 'Test101';" | mysql -u root -pTest101
    echo "GRANT ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TABLESPACE, CREATE VIEW, DROP, EVENT, INSERT, LOCK TABLES, REFERENCES, SELECT, SUPER, TRIGGER ON *.* TO 'fabric_restore'@'%';" | mysql -u root -pTest101
    echo "FLUSH PRIVILEGES;" | mysql -u root -pTest101 
    
    echo "CREATE USER 'fabric_backup'@'%' IDENTIFIED BY 'Test101';" | mysql -u root -pTest101
    echo "GRANT EVENT, EXECUTE, REFERENCES, SELECT, SHOW VIEW, TRIGGER ON *.* TO 'fabric_backup'@'%';" | mysql -u root -pTest101
    echo "FLUSH PRIVILEGES;" | mysql -u root -pTest101 
    
    touch #{Chef::Config[:file_cache_path]}/fabric_users.lock
EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/fabric_users.lock")}
end



template "/etc/mysql/fabric.cfg" do
  path "/etc/mysql/fabric.cfg"
  source "fabric.cfg"
  owner "root"
  group "root"
  mode "0644"
  #notifies :start, resources(:service => "mysql")
end

=begin
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








