server_type = node.name.split('-')[0]
slug = node.name.split('-')[1] 
datacenter = node.name.split('-')[2]
environment = node.name.split('-')[3]
location = node.name.split('-')[4]
cluster_slug = File.read("/var/cluster_slug.txt")
cluster_slug = cluster_slug.gsub(/\n/, "") 



data_bag("server_data_bag")
mysql_server = data_bag_item("server_data_bag", "mysql")
password = mysql_server[datacenter][environment][location][cluster_slug]['meta']['password']

#http://dev.mysql.com/doc/mysql-apt-repo-quick-guide/en/#repo-qg-apt-repo-manual-setup
#ALTER USER 'root'@'localhost' IDENTIFIED BY 'Test101';
#grant all privileges on *.* to 'root'@'%' identified by 'Test101';
#FLUSH PRIVILEGES;

directory "/data" do
  owner "root"
  group "root"
  mode "0777"
  action :create
end

=begin
directory "/data/mysql" do
  owner "mysql"
  group "mysql"
  mode "0700"
  action :create
end
=end

=begin
cookbook_file "#{Chef::Config[:file_cache_path]}/pubkey_mysql.asc" do
  source "pubkey_mysql.asc"
  mode 00544
end
=end

bash "install_mysql" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    gpg --recv-keys 5072E1F5  
    gpg --recv-keys 5072E1F5   
    gpg --export -a 5072e1f5 > pubkey_mysql.asc
    sudo apt-key add pubkey_mysql.asc
    echo 'deb http://repo.mysql.com/apt/ubuntu trusty mysql-5.7' | tee -a /etc/apt/sources.list.d/mysql.list
    sudo apt-get update
    export DEBIAN_FRONTEND=noninteractive
    apt-get -q -y install mysql-server
    touch #{Chef::Config[:file_cache_path]}/mysql.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/mysql.lock")}
end


bash "change_dir" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    service mysql stop
    service apparmor stop
    sed 's:/var/lib/mysql:/data/mysql:g' -i /etc/apparmor.d/usr.sbin.mysqld
    mv /var/lib/mysql /data
    service apparmor start
    touch #{Chef::Config[:file_cache_path]}/apparmor.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/apparmor.lock")}
end

service "mysql" do
  supports :start => true, :stop => true
end

=begin
File.exists?("/var/cluster_index.txt") 
  cluster_index = File.read("/var/cluster_index.txt")
  cluster_index = cluster_index.gsub(/\n/, "") 
else
   cluster_index = 0
=end

if server_type == "mysql"
  cluster_index = File.read("/var/cluster_index.txt")
  cluster_index = cluster_index.gsub(/\n/, "") 
  template "/etc/mysql/my.cnf" do
    path "/etc/mysql/my.cnf"
    source "my.5.7.index.cnf.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :start, resources(:service => "mysql")
    variables :cluster_index => cluster_index
    #variables {{:cluster_index => File.read("/var/cluster_index.txt").gsub(/\n/, "")}}
    #only_if {File.exists?("/var/cluster_index.txt")}
  end
=begin
  template "/etc/mysql/my.cnf" do
    path "/etc/mysql/my.cnf"
    source "my.5.7.standalone.cnf.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :start, resources(:service => "mysql")
    not_if {File.exists?("/var/cluster_index.txt")}
  end
=end
end



if server_type == "fabric"
  template "/etc/mysql/my.cnf" do
    path "/etc/mysql/my.cnf"
    source "my.5.7.fabric.cnf.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :start, resources(:service => "mysql")
  end
end


service "mysql" do
  supports :start => true, :stop => true
  action [ :enable, :start]
end




bash "add_user" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    service mysql start
    echo "CREATE USER 'root'@'%' identified by 'Test101';" | mysql -u root
    echo "ALTER USER 'root'@'%' identified by 'Test101';" | mysql -u root
    echo "grant all on *.* to 'root'@'%' with grant option;" | mysql -u root
    echo "FLUSH PRIVILEGES;" | mysql -u root
    
    echo "drop user 'root'@'localhost';" | mysql -u root -pTest101
    echo "FLUSH PRIVILEGES;" | mysql -u root -pTest101
    
    touch #{Chef::Config[:file_cache_path]}/mysql_user.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/mysql_user.lock")}
end




bash "install_fabric_user" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
  
    echo "CREATE USER 'fabric_server'@'%' IDENTIFIED BY 'Test101';" | mysql -u root -pTest101
    echo "grant all on *.* to 'fabric_server'@'%' with grant option;" | mysql -u root -pTest101
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




