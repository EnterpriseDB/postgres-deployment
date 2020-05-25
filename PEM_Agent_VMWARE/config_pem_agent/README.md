This option provided for registering pem agent with pem server which already exists. We are using ansible to configure cluster.

The playbook is here in config_pem_agent directory inside Pem_Agent_VMWARE directory. 

Open a hosts file in vi editor and provide all 3 server IP..


Run ansible playbooks as follows

ansible-playbook -i hosts installpemagent.yml --extra-vars='DB_ENGINE= USER= PASS= PEM_IP= DBPASSWORD= PEM_WEB_PASSWORD= EPASDBUSER= PGDBUSER='

Here

DB_ENGINE provide options like pg10 or pg11 or epas10 or epas12

USER is yum repo user name if DB_ENGINE is pg10,pg11,pg12.

PASS is yum repo user password if DB_ENGINE is pg10,pg11,pg12.

EPASDBUSER is DB username for EDB Postgres(leave blank if using community Postgres)

PGDBUSER is DB username for community Postgres(leave blank if using EDB Postgres)

DBPASSWORD is DB super user password

PEM_WEB_PASSWORD PEM server DB password.

PEM_IP is IP of PEM server.

Sample ansible playbook run example is

ansible-playbook -i hosts installpemagent.yml --extra-vars='DB_ENGINE=epas12 USER=james PASS=abc34566 PEM_IP=54.10.30.2 DBPASSWORD=postgres PEM_WEB_PASSWORD=adminpem EPASDBUSER=eenterprisedb PGDBUSER='




 



