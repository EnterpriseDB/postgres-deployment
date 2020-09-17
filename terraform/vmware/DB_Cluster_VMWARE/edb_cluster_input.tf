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
#############################################

### Optional Field in this config file

### EDB_yumrepo_username } Mandatory if selecting dbengine epas(all version) 
### EDB_yumrepo_password }
### replication_type (by default asynchronous)
### db_user (if you do not want to go with default DB user)
### db_password
### cpucore
### ramsize
### cluster_name
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


  # Enter vmware vsphere login username

  user = ""

  # Enter vmware vsphere login password

  password = ""

  # Enter vsphere web address

  vsphere_server = ""

  allow_unverified_ssl = true
}


module "edb-db-cluster" {
  # The source module used for creating clusters.

  source = "./EDB_SRSETUP_VMWARE"

  # Enter EDB yum repository credentials for usage of any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for usage of any EDB tools

  EDB_yumrepo_password = ""

  # Provide DB cluster name to tag. Leaving it blank will use dbengine name as a tag.

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

  # Select database engine(DB) version like pg10-postgresql version10, epas12-Enterprise Postgresql Advanced server etc..
  # DB version support V10-V12

  dbengine = ""

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user.

  db_user = ""

  # Enter custom dbpassword. By default it is 'postgres'

  db_password = ""

  # Select replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""

  # Enter replication user password

  replication_password = ""

}

output "Master-IP" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "Standby1-IP" {
  value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "Standby2-IP" {
  value = "${module.edb-db-cluster.Slave-IP-2}"
}

output "DBENGINE" {
  value = "${module.edb-db-cluster.DBENGINE}"
}

output "SSH-USER" {
  value = "${module.edb-db-cluster.SSH-USER}"
}

output "CLUSTER_NAME" {
  value = "${module.edb-db-cluster.CLUSTER_NAME}"
}
