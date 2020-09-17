###### Mandatory Fields in this config file #####
### ssh_user   
### ssh_password
### replication_password
### notification_email_address
### efm_role_password
### db_password
### pem_web_ui_password
### dcname
### EDB_yumrepo_username 
### EDB_yumrepo_password
### template_name
### ssh_user
### ssh_password
### user
### password
### vsphere_server
### datastore
### compute_cluster
### network 
#############################################

### Optional Field in this config file
### cpucore
### ramsize
### replication_type } by default asynchronous
###########################################

### Default User DB credentials##########

## You can change this any time

### For PG10, PG11, PG12
## Username: postgres
## Password: postgres

### For EPAS10, EPAS11, EPAS12
## Username: enterprisedb
## Password: postgres

########################################

provider "vsphere" {

  # Provide vmware vsphere login username

  user = ""

  # Provide vmware vsphere login password

  password = ""

  # Provide URL for vmware vsphere 

  vsphere_server = ""

  allow_unverified_ssl = true
}


module "edb-expand-db-cluster" {
  # The source module to be used.

  source = "./EDB_ADD_REPLICA_VMWARE"

  # Enter EDB yum repository credentials for usage of any EDB tools. 

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for usage of any EDB tools.

  EDB_yumrepo_password = ""

  # Provide vmware vsphere datacenter name....

  dcname = ""

  # Enter datastore name.

  datastore = ""

  # Enter Compute Cluster name.

  compute_cluster = ""

  # Enter network name

  network = ""

  # Enter number of CPU core for new VM. If you leave blank it will create with 2 core CPU

  cpucore = ""

  # Enter RAM Size for new VM. If you leave blank it will create with 1024 MB RAM

  ramsize = ""

  # Enter template name for base centos 7

  template_name = ""

  # Provide ssh user for login

  ssh_user = ""

  # Provide ssh password

  ssh_password = ""

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 

  db_user = ""

  # Enter DB password of server

  db_password = ""

  # Select replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""

  # Enter replication user password

  replication_password = ""

  # Enter EFM notification email address

  notification_email_address = ""

  # Enter EFM role password

  efm_role_password = ""

  # Enter Password of PEM WEB UI 

  pem_web_ui_password = ""

}

output "Standby-IP" {
  value = "${module.edb-expand-db-cluster.Slave-IP}"
}
