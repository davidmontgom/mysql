#https://computingforgeeks.com/install-mariadb-10-on-ubuntu-18-04-and-centos-7/

package "software-properties-common" do
  action :install
end


bash "mariadb_graphate_install" do
  cwd "/tmp/"
  code <<-EOH
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
	sudo add-apt-repository 'deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/10.3/ubuntu bionic main'
	sudo apt update
    touch #{Chef::Config[:file_cache_path]}/mariadb.lock
  EOH
  #creates "/usr/local/bin/redis-server"
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/mariadb.lock")}
end


bash "install_mariadb" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}"
  code <<-EOH
    export DEBIAN_FRONTEND=noninteractive
    apt-get -q -y install mariadb-server
    touch #{Chef::Config[:file_cache_path]}/mariadb-server.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/mariadb-server.lock")}
end

package "mariadb-client" do
  action :install
end

service "mariadb" do
  supports :start => true, :stop => true
  action [:enable, :start ]
end