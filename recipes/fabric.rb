

#http://dev.mysql.com/doc/mysql-utilities/1.5/en/fabric.html

sudo mkdir -p /usr/share/pyshared/mysql
wget http://dev.mysql.com/get/Downloads/Connector-Python/mysql-connector-python_2.1.3-1ubuntu14.04_all.deb
dpkg -i mysql-connector-python_2.1.3-1ubuntu14.04_all.deb
wget http://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-utilities_1.5.6-1ubuntu14.04_all.deb
dpkg -i mysql-utilities_1.5.6-1ubuntu14.04_all.deb



mysqlfabric manage start   --daemonize --config=/var/fabric.conf
mysqlfabric manage stop

echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '#{password}';" | mysql -u root -p#{password}
echo "grant all privileges on *.* to 'root'@'%' identified by '#{password}';" | mysql -u root -p#{password}
echo "FLUSH PRIVILEGES;" | mysql -u root -p#{password}




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



#http://dev.mysql.com/doc/mysql-utilities/1.5/en/fabric-quick-start-replication.html
mysqlfabric group create my_group
mysqlfabric group add my_group localhost:3307
mysqlfabric group add my_group localhost:3308
mysqlfabric group add my_group localhost:3309

mysqlfabric group lookup_servers my_group
mysqlfabric group health my_group








