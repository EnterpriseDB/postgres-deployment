###### Mandatory Fields in this config file #####
### EDB_yumrepo_username
### EDB_yumrepo_password
### db_password 
### dcname
### ssh_user
### ssh_password
### user
### password
### cpucore
### ramsize
### vsphere_server
### datastore
### compute_cluster
### network
### template_name
#############################################

### Optional Fields

### retention_period
#############################
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


module "edb-bart-server" {
  # The source module to be used.

  source = "./EDB_BART_Server"
  
  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_password = ""

  # Enter vmware vsphere data center name.
 
  dcname = ""

  # Enter number for cpu core for your new VM. By default it is 2 core.

  cpucore = ""

  # Enter RAM size for your new VM. By default it is 1024.

  ramsize = ""

  # Enter template name of base centos 7.

  template_name = ""

  # Enter datastore name

  datastore = ""
 
  # Enter Compute Cluster name

  compute_cluster = ""

  # Enter network name

  network = ""
  
  # Enter user name for ssh.

  ssh_user = ""

  # Enter password for ssh.
 
  ssh_password = ""

  # Enter DB user of remote DB server

  db_user = ""

  # Enter DB password of remote DB server.

  db_password = ""

  # Specify the retention policy for the backup. This determines when an
  #  active backup should be marked as obsolete. You can specify the retention policy either in terms of number
  #  of backup or in terms of duration (days, weeks, or months). eg 3 MONTHS or 7 DAYS or 1 WEEK
  # Leave it blank if you dont want to put any retention policy

  retention_period = ""

  # Provide size of additional disk where bart will store backup. This size is in GB. Eg. size = 10 will create 10GB disk.
 
  size = 

}  

output "Bart_SERVER_IP" {
  value = "${module.edb-bart-server.Bart-IP}"
}


