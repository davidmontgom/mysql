import json
import os
import sys
import paramiko
import dns.resolver
import hashlib
import zc.zk
import logging 
logging.basicConfig()
from kazoo.client import KazooClient
import os
from boto.route53.connection import Route53Connection
from boto.route53.record import ResourceRecordSets
from boto.route53.record import Record
import time


"""
1) write to zk the current primaries and secondaries
2) if primary changes update druid dns for primary

write an HA script that will use existing nodes
if serves dies this is true
1) you have data in /fabric-%s-%s/
2) queries mysql paths and get address and make sure they match, if not then 100% mysql and fabric rebuild
3) auto add groups and add slave and primary
"""

# running_in_pydev = 'PYDEV_CONSOLE_ENCODING' in os.environ
# if running_in_pydev==False:

HOME = os.path.expanduser("~")

SETTINGS_FILE='%s/.bootops.yaml' % HOME.rstrip('/')
SETTINGS_FILE='/root/.bootops.yaml'
from yaml import load, dump
from yaml import Loader, Dumper
f = open(SETTINGS_FILE)
parms = load(f, Loader=Loader)
f.close()
#parms = parms['forex']


environment = parms['environment']
location = parms['location']
datacenter = parms['datacenter']
node_name = parms['nodename']
slug = parms['slug']
this_server_type = parms['server_type']
settings_path = parms['settings_path']
aws_access_key_id = parms['AWS_ACCESS_KEY_ID']
aws_secret_access_key = parms['AWS_SECRET_ACCESS_KEY']


with open('%s/meta_data_bag/aws.json' % (settings_path.rstrip('/'))) as data_file:
    aws = json.loads(data_file.read())
    
domain = aws[environment]['route53']['domain']
zone_id = aws[environment]['route53']['zone_id']

if os.path.isfile('/var/cluster_slug.txt'):
    cluster_slug = open("/var/cluster_slug.txt").readlines()[0].strip()
else:
    cluster_slug = "nocluster"


#output = ['Fabric UUID:  5ca1ab1e-a007-feed-f00d-cab3fe13249e\n', 'Time-To-Live: 1\n', '\n', '                         server_uuid            address    status       mode weight\n', '------------------------------------ ------------------ --------- ---------- ------\n', '8af1be99-c191-11e5-8949-04019e3fc401  192.34.58.37:3306   PRIMARY READ_WRITE    1.0\n', 'bb14bc32-c18f-11e5-b823-04019e3f1b01 192.34.56.199:3306 SECONDARY  READ_ONLY    1.0\n', '\n', '\n']
#scp fabric_add_servers_monitor.py root@192.81.208.99:/var/fabric_test.py
def get_zk_host_list():
    
    if os.path.isfile('/var/zookeeper_hosts_overide.lock'):
        zk_host_list_dns = open('/var/zookeeper_hosts.json').readlines()[0].strip()
        zk_host_list_dns = zk_host_list_dns.split(',')
        zookeeper_hosts = zk_host_list_dns
    else:
        zookeeper_hosts = []
        for i in xrange(int(self.zk_count)):
            zookeeper_hosts.append( "%s-%s" % (i+1,self.zk_hostname) )
            
    zk_host_list = []
    for zk_host in  zookeeper_hosts:
            zk_host_list.append(zk_host+':2181')

    zk_host_str = ','.join(zk_host_list)  
    
#     zk_host_list_dns = open('/var/zookeeper_hosts.json').readlines()[0]
#     zk_host_list_dns = zk_host_list_dns.split(',')
#     zk_host_list = []
#     for aname in zk_host_list_dns:
#         try:
#             data =  dns.resolver.query(aname.strip(), 'A')
#             zk_host_list.append(data[0].to_text()+':2181')
#         except:
#             print 'ERROR, dns.resolver.NXDOMAIN',aname
            
    return zk_host_str

def get_zk_conn():
    zk_host_list = get_zk_host_list()
    if zk_host_list:
        zk = KazooClient(hosts=zk_host_list, read_only=True)
        zk.start()
    else:
        zk = None
        print 'waiting for zk conn...'
        time.sleep(1)
    return zk

zk = None
while zk==None:
    zk = get_zk_conn()
    
def create_domain(subdomain,ip_address,ttl=60,weight=None,identifier=None,region=None):

        domain = aws[environment]['route53']['domain']
        zone_id = aws[environment]['route53']['zone_id']
        
        conn = Route53Connection(aws_access_key_id, aws_secret_access_key)
        changes = ResourceRecordSets(conn, zone_id)
        subdomain = '%s.%s.' % (subdomain,domain)
        print "CREATE", subdomain, "A", ttl, weight, identifier
        change = changes.add_change("CREATE", subdomain, "A", ttl=ttl, weight=weight, identifier=identifier,region=region)
        change.add_value(ip_address)
        changes.commit()

def update_domain(subdomain,ip_address_list=[],ttl=60,weight=None,identifier=None,region=None):

        domain = aws[environment]['route53']['domain']
        zone_id = aws[environment]['route53']['zone_id']
        
        conn = Route53Connection(aws_access_key_id, aws_secret_access_key)
        changes = ResourceRecordSets(conn, zone_id)
        subdomain = '%s.%s.' % (subdomain,domain)
        change = changes.add_change("UPSERT", subdomain, "A", ttl=ttl,weight=weight,identifier=identifier,region=region)
        for ip_address in ip_address_list:
            change.add_value(str(ip_address))
        changes.commit()
             
def create_fabric_group():
    
    """
    /var/chef/cache/zookeeper.ok
    
    create fabric group if /var/chef/cache/druid.fabric.lock does not exists
    
    
    mysqlfabric group activate druid
    """
    created = False
    group_exists = False
    cmd = "mysqlfabric group create %s" % cluster_slug
    output = os.popen(cmd).readlines()
    for out in output:
        if out.find('GroupError: Group (%s) already exists.' % (cluster_slug))>=0:
            group_exists = True
        if out.find('Fabric UUID:')>=0:
            group_exists = False
            created = True
            os.system('touch /var/chef/cache/%s.fabric.lock' % (cluster_slug))
            
    return group_exists
           
def get_druid_primary():
    
    zk_host_list_dns = 'primary-mysql-%s-%s-%s-%s-druid.%s' % (slug,datacenter,environment,location,domain)
    zk_host_list_dns = zk_host_list_dns.split(',')
    primary_host = None
    for aname in zk_host_list_dns:
        try:
            data =  dns.resolver.query(aname, 'A')
            primary_host = data[0].to_text()
        except:
            print 'ERROR, dns.resolver.NXDOMAIN',aname
    return primary_host 

def get_zk_mysql_servers():   
    
    ip_address_list = [] 
    path = '/mysql-%s-%s-%s-%s-%s/' % (slug,datacenter,environment,location,cluster_slug)
    if zk.exists(path):
        addresses = zk.get_children(path)
        ip_address_list = list(set(addresses))
        
    return ip_address_list
  

while True:
    secondary_ip_list = None
    primary_ip_address = None 
    
    if not os.path.exists('/var/chef/cache/%s.fabric.lock' % (cluster_slug)):      
        group_exists = create_fabric_group() 
    else:
        group_exists = True
       
    primary_ip_address = None
    secondary_ip_list = [] 
    
    zk_mysql_servers = get_zk_mysql_servers()
    
    
    if group_exists:
        try:
            cmd = 'mysqlfabric group lookup_servers %s' % cluster_slug
            output = os.popen(cmd).readlines()
          
            for out in output:
                out = out.strip()
                if out.find('PRIMARY')>=0:
                    temp = out.split(' ')
                    for t in temp:
                        if t.find(':')>=0:
                            primary_ip_address = t.split(':')[0].strip()
                if out.find('SECONDARY')>=0:
                    temp = out.split(' ')
                    for t in temp:
                        if t.find(':')>=0:
                            secondary_ip_list.append(t.split(':')[0].strip())
        except:
            print 'fabric error'
    
    if primary_ip_address:
        fabric_mysql_servers = secondary_ip_list + [primary_ip_address]
    else:
        fabric_mysql_servers = secondary_ip_list
        
    print 'primary_ip_address:',primary_ip_address  
    print 'secondary_ip_list:',secondary_ip_list
    print 'fabric_servers:', fabric_mysql_servers
    print 'zk_mysql_servers:',zk_mysql_servers
    
    new_mysql_servers = []
    for mysql in zk_mysql_servers:
        if mysql not in fabric_mysql_servers:
            new_mysql_servers.append(mysql)
    
    print 'new_mysql_servers:',new_mysql_servers
    for mysql in new_mysql_servers:
        cmd = "mysqlfabric group add %s %s:3306" % (cluster_slug,mysql)
        output = os.popen(cmd).readlines()
        if primary_ip_address==None:
            cmd = "mysqlfabric group promote %s" % (cluster_slug)
            output = os.popen(cmd).readlines()
            cmd = "mysqlfabric group activate %s" % (cluster_slug)
            output = os.popen(cmd).readlines()
            
            
            print output
        else:
            print "primary exists"

    if cluster_slug=='druid' and primary_ip_address:
        druid_primary_host = get_druid_primary()
        print 'druid_primary_host:',druid_primary_host
        subdomain = 'primary-mysql-%s-%s-%s-%s-druid' % (slug,datacenter,environment,location)
        if not druid_primary_host:
            create_domain(subdomain,primary_ip_address,ttl=60,weight=None,identifier=None,region=None)
        
        if druid_primary_host != primary_ip_address:
            update_domain(subdomain,ip_address_list=[primary_ip_address],ttl=60,weight=None,identifier=None,region=None)
        
    #We know we have a new server when the node names do not match
    
    if primary_ip_address and secondary_ip_list:
        try:
            path = '/fabric-%s-%s/' % (slug,cluster_slug)
            if zk.exists(path)==None:
                zk.create(path,'', ephemeral=False)
            data = {}
            data['node_name']=node_name
            data['primary_ip_address']=primary_ip_address
            data['secondary_ip_list']=secondary_ip_list
            data = json.dumps(data)
            
            res = zk.set(path, data)
        except:
            get_zk_conn()
        
    sys.stdout.flush()
    sys.stderr.flush()
    time.sleep(2)
        
    
    
    
    
    


