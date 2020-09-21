This option provided for configuring EDB BART on VM which already exists. We are using ansible to configure BART.

The playbook is here in config_bart directory inside BART_AWS directory. 

Open a hosts file in vi editor and provide BART server IP and Master Database server IP from which we are going to take back up regularly.

Make sure you created additional EDB volume and attached that to ec2 instance. Do not format and mount it. We will take care of this in ansible playbook.

The lable to volume must be xvdf or sdf else ansible playbook will fail.


Run ansible playbooks as follows

ansible-playbook -i hosts   bartserver.yml --extra-vars='USER= PASS= BART_IP= DB_IP= DB_ENGINE= DB_PASSWORD= DB_USER= RETENTION_PERIOD='

Here

USER is EDB yum repository username to download package for BART

PASS is EDB yum repository user password.

BART_IP is Bart server public IP address

DB_IP is Database server IP from which Bart server taking backup.

DB_ENGINE is database engine installed on Master server. Eg pg12 or epas12

DB_PASSWORD is Database server super user password.

DB_USER is database server super username.

RETENTION_PERIOD is days or week you want to keep backup on BART server. You can leave this field blank.


Sample ansible playbook run example is


ansible-playbook -i hosts   bartserver.yml --extra-vars='USER=myname PASS=admine@123 BART_IP=50.2.3.5 DB_IP=112.30.1.3 DB_ENGINE=pg12 DB_PASSWORD=postgres DB_USER=postgres RETENTION_PERIOD='




 



