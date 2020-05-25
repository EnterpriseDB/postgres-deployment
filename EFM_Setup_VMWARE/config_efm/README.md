This option provided for configuring EFM on 3 node DB cluster which already exists. We are using ansible to configure cluster.

The playbook is here in config_efm directory inside EFM_Setup_VMWARE directory. 

Open a hosts file in vi editor and provide all 3 server public IP..


Run ansible playbooks as follows

ansible-playbook -i hosts setupefm.yml --extra-vars='DB_ENGINE= USER= PASS= DBUSER= EFM_USER_PASSWORD= MASTER= SLAVE1= SLAVE2= NOTIFICATION_EMAIL='

Here

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

USER is EDB yum repo user name

PASS is EDB yum repo user password.

DBUSER is database super username.

EFM_USER_PASSWORD is password for EFM role.

MASTER is master server  IP.

SLAVE1 is slave1  IP.

SLAVE2 is slave2 IP


NOTIFICATION_EMAIL is email address for EFM notification.



Sample ansible playbook run example is

ansible-playbook -i hosts setupefm.yml --extra-vars='DB_ENGINE=pg12 USER=james PASS=fhmdb123 DBUSER=postgres EFM_USER_PASSWORD=admin MASTER=54.30.1.1 SLAVE1=54.30.1.2 SLAVE2=54.30.1.3  NOTIFICATION_EMAIL=abc@gmail.com'



 



