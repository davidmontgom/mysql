Issues

* Main is is installing keys 
* In aws test if attachement exists
* creating users did not work

#issues with root privlages
http://stackoverflow.com/questions/1709078/how-can-i-restore-the-mysql-root-user-s-full-privileges
http://stackoverflow.com/questions/24027487/how-can-i-restore-the-mysql-root-user-s-full-privileges?rq=1


https://dev.mysql.com/doc/mysql-utilities/1.5/en/connector-python-fabric.html
http://dev.mysql.com/doc/mysql-utilities/1.5/en/fabric-faq.html
https://blogs.oracle.com/jbalint/entry/accessing_fabric_ha_groups_from
https://dev.mysql.com/tech-resources/articles/mysql-fabric-ga.html
mysqlfabric manage setup --param=storage.user=fabric
mysqlfabric group create druid
mysqlfabric group add druid 192.34.59.251:3306
mysqlfabric group promote druid
mysqlfabric group health druid
mysqlfabric group lookup_servers druid


mysqlfabric group add druid 192.34.58.37:3306
mysqlfabric group add druid 192.34.56.199:3306




slave mysqlfabric group remove druid 192.34.59.251:3306

mysqlfabric group remove druid 192.34.59.181:3306
mysqlfabric group add druid 192.34.56.66:3306

mysqlfabric group promote druid


https://github.com/druid-io/druid/issues/1701

drop user fabric_server;
flush privileges;
CREATE USER 'fabric_server'@'%' IDENTIFIED BY 'Test101';
grant all on *.* to 'fabric_server'@'%' identified by 'Test101';





http://bugs.mysql.com/bug.php?id=72281
https://www.percona.com/blog/2014/05/15/high-availability-mysql-fabric-part/


########################################
mysqlfabric group create frontend_global
mysqlfabric group create frontend_shard1
mysqlfabric group create frontend_shard2

mysqlfabric group add frontend_global 172.31.20.251:3306
mysqlfabric group add frontend_shard1 172.31.24.137:3306
mysqlfabric group add frontend_shard2 172.31.21.246:3306

mysqlfabric group promote frontend_global
mysqlfabric group promote frontend_shard1
mysqlfabric group promote frontend_shard2


mysqlfabric sharding create_definition HASH frontend_global
mysqlfabric sharding add_table 1 employees.salaries emp_no
mysqlfabric sharding add_table 1 employees.wow emp_no



# http://pycoder.net/bospy/presentation.html#create-user-correct
# @limit(requests=100, interval=3600, by="ip")

#create database and tables in global

mysqlfabric sharding add_shard 1 "frontend_shard1, frontend_shard2" --state=ENABLED


mysqlfabric sharding list_definitions

mapping_id type_name global_group_id
---------- --------- ---------------
         1      HASH frontend_global


mysqlfabric  sharding list_tables HASH

mapping_id type_name         table_name    global_group column_name
---------- --------- ------------------ --------------- -----------
         1      HASH employees.salaries frontend_global      emp_no
         1      HASH      employees.wow frontend_global      emp_no
         
         
sharding lookup_servers employees.wow emp_no
  
                         server_uuid            address  status       mode weight
------------------------------------ ------------------ ------- ---------- ------
c5d2779d-f970-11e5-a9b4-06e28cfb1059 172.31.21.246:3306 PRIMARY READ_WRITE    1.0






# Create a new table
mysqlfabric sharding add_table 1 api.driver_register partner_driver_ref

mysqlfabric sharding add_table 1 api.driver_register driver_id

mysqlfabric sharding add_table 1 api.driver driver_id           
mysqlfabric sharding add_table 1 api.driver_payment_method driver_id 

#mysqlfabric sharding add_table 1 api.driver_register driver_id  
#mysqlfabric sharding add_table 1 api.driver_social_profile driver_id 

mysqlfabric sharding add_table 1 api.driver_trip driver_id           
mysqlfabric sharding add_table 1 api.driver_trip_json driver_id     
mysqlfabric sharding add_table 1 api.driver_vehicle driver_id 

mysqlfabric sharding list_tables HASH

#Remove Def
mysqlfabric sharding lookup_table driver_trip
Fabric UUID 5ca1ab1e-a007-feed-f00d-cab3fe13249e
mysqlfabric sharding remove_definition 5ca1ab1e-a007-feed-f00d-cab3fe13249e



mysqlfabric sharding add_table 1 api.trip driver_id 





