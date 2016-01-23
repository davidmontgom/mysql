Issues

* Main is is installing keys 
* In aws test if attachement exists
* creating users did not work


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


master mysqlfabric group remove druid 208.68.38.219:3306
slave mysqlfabric group remove druid 192.34.59.251:3306

mysqlfabric group add druid 192.34.59.181:3306
mysqlfabric group add druid 192.34.56.66:3306

mysqlfabric group promote druid


https://github.com/druid-io/druid/issues/1701