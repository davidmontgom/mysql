remote_file "#{Chef::Config[:file_cache_path]}/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb" do
    source "https://dev.mysql.com/get/Downloads/Connector-Python/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb"
    action :create_if_missing
end

dpkg_package "#{Chef::Config[:file_cache_path]}/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb" do
  action :install
end 


remote_file "#{Chef::Config[:file_cache_path]}/mysql-connector-python-py3_2.1.3-1ubuntu14.04_all.deb" do
    source "http://dev.mysql.com/get/Downloads/Connector-Python/mysql-connector-python-py3_2.1.3-1ubuntu14.04_all.deb"
    action :create_if_missing
end

dpkg_package "#{Chef::Config[:file_cache_path]}/mysql-connector-python-py3_2.1.3-1ubuntu14.04_all.deb" do
  action :install
end 

