This option provided for configuring pem monitoring server which already exists. We are using ansible to configure server.

The playbook is here in config_pem_server directory inside Pem_Server_AWS directory. 

Open a hosts file in vi editor and provide server public IP


Run ansible playbooks as follows

ansible-playbook -i hosts pemserver.yml --extra-vars='USER= PASS= DB_PASSWORD= PEM_IP='

Here

USER is yum repo user name if DB_ENGINE is pg10,pg11,pg12.

PASS is yum repo user password if DB_ENGINE is pg10,pg11,pg12.

PEM_IP is IP of PEM server.

DB_PASSWORD is password for PEM server local DB


Sample ansible playbook run example is

ansible-playbook -i hosts pemserver.yml --extra-vars='USER=james PASS=sasfas345 DB_PASSWORD=adminpem PEM_IP=104.30.9.10'



 



