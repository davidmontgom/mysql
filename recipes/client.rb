
remote_file "#{Chef::Config[:file_cache_path]}/mysql-connector-python_8.0.13-1ubuntu18.10_all.deb" do
    source "https://dev.mysql.com/get/Downloads/Connector-Python/mysql-connector-python_8.0.13-1ubuntu18.10_all.deb"
    action :create_if_missing
end

dpkg_package "#{Chef::Config[:file_cache_path]}/mysql-connector-python_8.0.13-1ubuntu18.10_all.deb" do
  action :install
end 



