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



bash "install_mysql" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
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

service "mysql" do
  action :stop
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/mysql.lock")}
end


bash "change_dir" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    service apparmor stop
    sed 's:/var/lib/mysql:/data/mysql:g' -i /etc/apparmor.d/usr.sbin.mysqld
    mv /var/lib/mysql /data
    service apparmor start
    touch #{Chef::Config[:file_cache_path]}/apparmor.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/apparmor.lock")}
end

    

template "/etc/mysql/my.cnf" do
  path "/etc/mysql/my.cnf"
  source "my.5.7.cnf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :start, resources(:service => "mysql")
end


service "mysql" do
  supports :start => true, :stop => true
  action [ :enable, :start]
end



bash "add_user" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '#{password}';" | mysql -u root -p#{password}
    echo "grant all privileges on *.* to 'root'@'%' identified by '#{password}';" | mysql -u root -p#{password}
    echo "FLUSH PRIVILEGES;" | mysql -u root -p#{password}
    touch #{Chef::Config[:file_cache_path]}/mysql_user.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/mysql_user.lock")}
end

=begin
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Test101';" | mysql -u root -pTest101
echo "grant all privileges on *.* to 'root'@'%' identified by 'Test101';" | mysql -u root -pTest101
echo "FLUSH PRIVILEGES;" | mysql -u root -pTest101
=end



