###### Mandatory Fields in this config file #####
### dcname
### ssh_user
### ssh_password
### dbengine
### replication_password
### user
### password
### template_name
### datastore
### compute_cluster
### network
### efm_role_password
### notification_email_address
### db_password_pem
### cpucore_pem
### ramsize_pem
#############################################

### Optional Field in this config file

### replication_type (by default asynchronous)
### db_user (if you do not want to go with default DB user)
### db_password
### cpucore
### ramsize
### cluster_name
###########################################

### Default User DB credentials##########

### For EPAS12
## Username: enterprisedb
## Password: postgres

########################################

provider "vsphere" {

  version = "1.15"

  # Enter vmware vsphere login username
 
  user = ""

  # Enter vmware vsphere login password

  password = ""

  # Enter vsphere web address

  vsphere_server = ""

  allow_unverified_ssl =  true
}


module "edb-db-cluster" {
  # The source module used for creating clusters.
  
  source = "./EDB_Tools"
  
  # Enter EDB yum repository credentials for usage of any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for usage of any EDB tools

  EDB_yumrepo_password = ""

  # Provide cluster name to tag for your DB cluster. If you leave it blank we will use default tag which is epas12.

  cluster_name = ""

  # Enter vmware vsphere data center name.
 
  dcname = ""

  # Enter datastore name.

  datastore = ""
 
  # Enter Compute Cluster name.

  compute_cluster = ""

  # Enter network name.

  network = ""

  # Enter number for cpu core for your new VM. By default it is 2 core.

  cpucore = ""

  # Enter RAM size for your new VM. By default it is 1024.

  ramsize = ""

  # Enter template name of base centos 7.

  template_name = ""
  
  # Enter user name for ssh.

  ssh_user = ""

  # Enter password for ssh.
 
  ssh_password = ""

  
  # Enter optional database (DB) User, leave it blank to use default user else enter desired user.

  db_user = ""

  # Enter custom dbpassword. By default it is 'postgres'

  db_password = ""

  # Select replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".
 
  replication_type = ""
  
  # Enter replication user password

  replication_password = ""

  #### EFM SET UP BEGINE HERE ####

  # Provide EFM role password

  efm_role_password = ""

  # Provide EFM notification email address to receive cluster health notification or any change in status.

  notification_email_address = ""


 #### PEM MONITORING SERVER SET UP BEGINE HERE #### 

  # Provide CPU core for PEM monitoring server. By default it is 2 core.

  cpucore_pem = ""

  # Provide RAM size for PEM. By default it is 1024 MB.

  ramsize_pem = ""

  # Provide PEM monitoring server DB password

  db_password_pem = "" 

  ##### BART SET UP START HERE ###

  # Enter number for cpu core for your new VM. By default it is 2 core.

  cpucore_bart = ""

  # Enter RAM size for your new VM. By default it is 1024.

  ramsize_bart = ""

  # Specify the retention policy for the backup. This determines when an
  #  active backup should be marked as obsolete. You can specify the retention policy either in terms of number
  #  of backup or in terms of duration (days, weeks, or months). eg 3 MONTHS or 7 DAYS or 1 WEEK
  # Leave it blank if you dont want to put any retention policy

  retention_period = ""

  # Provide size of additional disk where bart will store backup. This size is in GB. Eg. size = 10 will create 10GB disk.
 
  size = 
  
}  

output "A_Master-IP" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "B_Standby1-IP" {
  value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "C_Standby2-IP" {
  value = "${module.edb-db-cluster.Slave-IP-2}"
}

output "D_PEM_Server_IP" {
 
  value = "${module.edb-db-cluster.PEM-Server}"
}

output "E_PEM_AGENT1" {
value = "${module.edb-db-cluster.Master-IP}"
}

output "F_PEM_AGENT2" {
value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "G_PEM_AGENT3" {
value = "${module.edb-db-cluster.Slave-IP-1}"
}
 
output "H_Bart_SERVER_IP" {
  value = "${module.edb-db-cluster.Bart-IP}"
}

