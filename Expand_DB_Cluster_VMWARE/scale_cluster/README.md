This option provided for scale DB Cluster on ec2-instance which already exists. We are using ansible to configure cluster.

The playbook is here in scale_cluster directory inside Expand_DB_Cluster_AWS directory. 

Open a hosts file in vi editor and provide all 4 server public IP..


Run ansible playbooks as follows

ansible-playbook -i hosts expandcluster.yml --extra-vars='USER= PASS= PGDBUSER= EPASDBUSER= DB_ENGINE= EFM_USER_PASSWORD= NOTIFICATION_EMAIL= PEM_IP= PEM_WEB_PASSWORD= DBPASSWORD= REPLICATION_USER_PASSWORD= REPLICATION_TYPE= ip1= ip2= ip3= MASTER= SLAVE1= SLAVE2= NEWSLAVE='

Here

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

USER is EDB yum repo user name

PASS is EDB yum repo user password.

EPASDBUSER is DB super username for EDB postgres(leave blank if using community postgres)

PGDBUSER is DB super username for community postgres(leave blank if using EDB postgres)

ip1 is internal IP of master server

ip2 is internal IP of slave1

ip3 is internal IP of slave2

REPLICATION_USER_PASSWORD is replication user/role password.

DBPASSWORD is DB super user password.

REPLICATION_TYPE synchronous or asynchronous

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

MASTER is master server IP

SLAVE1 is slave1 server IP

SLAVE2 is slave2 server IP

EFM_USER_PASSWORD is password for EFM role.

NOTIFICATION_EMAIL is email address for EFM notification.

NEWSLAVE is  IP of new server

NOTIFICATION_EMAIL is email address for EFM notification.

PEM_WEB_PASSWORD PEM server DB password.

PEM_IP is IP of PEM server.

EFM_USER_PASSWORD is password for role created for EFM operations.


Sample ansible playbook run example is

ansible-playbook -i hosts expandcluster.yml --extra-vars='USER=james PASS=admine123 PGDBUSER=postgres EPASDBUSER= DB_ENGINE=pg12 EFM_USER_PASSWORD=adminedb NOTIFICATION_EMAIL=manish.ingole@enterprisedb.com PEM_IP=172.22.17.37 PEM_WEB_PASSWORD=adminedb DBPASSWORD=postgres REPLICATION_USER_PASSWORD=adminedb REPLICATION_TYPE=synchronous ip1=172.22.17.39 ip2=172.22.17.38 ip3=172.22.17.39 MASTER=172.22.17.40 SLAVE1=172.22.17.38 SLAVE2=172.22.17.39 NEWSLAVE=172.22.17.41'


 



