
#http://dev.mysql.com/doc/mysql-apt-repo-quick-guide/en/#repo-qg-apt-repo-manual-setup



#ALTER USER 'root'@'localhost' IDENTIFIED BY 'Feed312!';
#grant all privileges on *.* to 'root'@'%' identified by 'Feed312!';
#FLUSH PRIVILEGES;

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
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/mysql_lock")}
end
=begin
template "/etc/mysql/my.cnf" do
  path "/etc/mysql/my.cnf"
  source "my.5.7.cnf.erb"
  owner "root"
  group "root"
  mode "0644"
end
=end