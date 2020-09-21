This option provided for configuring EFM on 3 node DB cluster which already exists. We are using ansible to configure cluster.

The playbook is here in config_efm directory inside EFM_Setup_AWS directory. 

Open a hosts file in vi editor and provide all 3 server public IP..


Run ansible playbooks as follows

ansible-playbook -i hosts setupefm.yml --extra-vars='DB_ENGINE= USER= PASS= DBUSER= EFM_USER_PASSWORD= MASTER= SLAVE1= SLAVE2= ip1= ip2= ip3= NOTIFICATION_EMAIL= REGION_NAME= S3BUCKET='

Here

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

USER is EDB yum repo user name

PASS is EDB yum repo user password.

DBUSER is database super username.

EFM_USER_PASSWORD is password for EFM role.

MASTER is master server public IP.

SLAVE1 is slave1 public IP.

SLAVE2 is slave2 public IP

ip1 is master server internal IP.

ip2 is slave1 server internal IP.

ip3 is slave2 server internal IP.

NOTIFICATION_EMAIL is email address for EFM notification.

REGION_NAME is AWS region code.

S3BUCKET is S3 bucketname followed by foldername(Eg. bucketname/folder name)

Sample ansible playbook run example is

ansible-playbook -i hosts setupefm.yml --extra-vars='DB_ENGINE=pg12 USER=james PASS=fhmdb123 DBUSER=postgres EFM_USER_PASSWORD=admin MASTER=54.30.1.1 SLAVE1=54.30.1.2 SLAVE2=54.30.1.3 ip1=172.30.1.1 ip2=17230.1.2 ip3=172.30.1.3 NOTIFICATION_EMAIL=abc@gmail.com REGION_NAME=us-east-1 S3BUCKET=/mybucket/wal'



 



