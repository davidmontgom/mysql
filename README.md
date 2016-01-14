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
mysqlfabric group add druid 198.211.97.48:3306
mysqlfabric group promote druid
mysqlfabric group health druid
mysqlfabric group lookup_servers druid