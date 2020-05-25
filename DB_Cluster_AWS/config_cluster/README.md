This option provided for configuring DB Cluster on ec2-instance which already exists. We are using ansible to configure cluster.

The playbook is here in config_cluster directory inside DB_Cluster_AWS directory. 

Open a hosts file in vi editor and provide all 3 server public IP..


Run ansible playbooks as follows

ansible-playbook -i hosts  setupsr.yml --extra-vars='USER= PASS= EPASDBUSER= PGDBUSER= ip1= ip2= ip3= S3BUCKET= REPLICATION_USER_PASSWORD= DBPASSWORD= REPLICATION_TYPE= DB_ENGINE= MASTER= SLAVE1= SLAVE2='

Here

USER is EDB yum repo user name(If using EDB postgres)

PASS is EDB yum repo user password

EPASDBUSER is DB username for EDB postgres(leave blank if using community postgres)

PGDBUSER is DB username for community postgres(leave blank if using EDB postgres)

ip1 is internal IP of master server

ip2 is internal IP of standby1

ip3 is internal IP of standby2

S3BUCKET is S3 bucketname followed by foldername(Eg. bucketname/folder name)

REPLICATION_USER_PASSWORD is replication user/role password.

DBPASSWORD is DB password.

REPLICATION_TYPE synchronous or asynchronous

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

MASTER is master server public IP

SLAVE1 is slave1 server public IP

SLAVE2 is slave2 server public IP

Sample ansible playbook run example is

ansible-playbook -i hosts  setupsr.yml --extra-vars='USER= PASS= EPASDBUSER= PGDBUSER=postgres ip1=10.0.2.3 ip2=10.0.2.2 ip3=10.0.2.1 S3BUCKET=/mydbbackup/wal REPLICATION_USER_PASSWORD=admin DBPASSWORD=postgres REPLICATION_TYPE=synchronous DB_ENGINE=pg12 MASTER=114.2.5.7 SLAVE1=54.3.5.6 SLAVE2=53.2.3.1'




 



