This option provided for scale DB Cluster on ec2-instance which already exists. We are using ansible to configure cluster.

The playbook is here in scale_cluster directory inside Expand_DB_Cluster_AWS directory. 

Open a hosts file in vi editor and provide all 4 server public IP..


Run ansible playbooks as follows

ansible-playbook -i hosts expandcluster.yml --extra-vars='DB_ENGINE= USER= PASS= PGDBUSER= EPASDBUSER= NEWSLAVE= REPLICATION_USER_PASSWORD=  REPLICATION_TYPE= ip1= ip2= ip3=  IPPRIVATE= NOTIFICATION_EMAIL= MASTER= SLAVE1= SLAVE2= DBPASSWORD= PEM_IP= PEM_WEB_PASSWORD= S3BUCKET= EFM_USER_PASSWORD= REGION_NAME='

Here

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

USER is EDB yum repo user name

PASS is EDB yum repo user password.

EPASDBUSER is DB super username for EDB postgres(leave blank if using community postgres)

PGDBUSER is DB super username for community postgres(leave blank if using EDB postgres)

ip1 is internal IP of master server

ip2 is internal IP of slave1

ip3 is internal IP of slave2

IPPRIVATE is internal ip of slave3

REPLICATION_USER_PASSWORD is replication user/role password.

DBPASSWORD is DB password.

REPLICATION_TYPE synchronous or asynchronous

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

MASTER is master server public IP

SLAVE1 is slave1 server public IP

SLAVE2 is slave2 server public IP

EFM_USER_PASSWORD is password for EFM role.

NOTIFICATION_EMAIL is email address for EFM notification.

NEWSLAVE is public IP of new server

NOTIFICATION_EMAIL is email address for EFM notification.

DBPASSWORD is DB password

PEM_WEB_PASSWORD PEM server DB password.

PEM_IP is IP of PEM server.

S3BUCKET is bucket name where wal file stored and used to restore backups.

EFM_USER_PASSWORD is password for role created for EFM operations.

REGION_NAME is region code where resource deployed.

Sample ansible playbook run example is

ansible-playbook -i hosts expandcluster.yml --extra-vars='DB_ENGINE=pg12 USER=ppcd PASS=7395820116e32bf3d016208fb151ef60 PGDBUSER=postgres EPASDBUSER= NEWSLAVE=54.237.98.203 REPLICATION_USER_PASSWORD=adminedb REPLICATION_TYPE=asynchronous ip1=172.31.49.234 ip2=172.31.54.150 ip3=172.31.51.226  IPPRIVATE=172.31.56.85 NOTIFICATION_EMAIL=manish.ingole@enterprisedb.com MASTER=54.144.155.234 SLAVE1=3.84.255.58 SLAVE2=54.145.240.65 DBPASSWORD=postgres PEM_IP=100.24.235.182 PEM_WEB_PASSWORD=adminedb S3BUCKET=edb-ark/wal EFM_USER_PASSWORD=adminedb REGION_NAME=us-east-1'



 



