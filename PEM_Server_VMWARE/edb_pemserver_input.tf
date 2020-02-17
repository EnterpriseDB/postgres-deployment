###### Mandatory Fields in this config file #####
### ssh_password   
### ssh_user
### EDB_yumrepo_username
### EDB_yumrepo_password
### db_password 
### template_name
### dcname
### user
### password
### vsphere_server
#############################################
##### Optional values
### cpucore
### ramsize
#############################################

provider "vsphere" {

  # Provide vmware vsphere user name

  user = ""

  # Provide vmware vsphere user password

  password = ""

  # Provide vmware vsphere URL

  vsphere_server = ""

  allow_unverified_ssl =  true
}

module "edb-pem-server" {
  # The source module to be used.

   source = "./EDB_PEM_SERVER_VMWARE"
  
  # Enter EDB yum repository credentials for any EDB tools.

   EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for any EDB tools.

   EDB_yumrepo_password = ""

  # Provide vmware vsphere data center name
  
   dcname = ""

  # Enter cpu core for new VM. By default it is 2
 
   cpucore = ""
 
  # Enter RAM size for new VM. By default it is 1024
 
   ramsize = ""
    
  # Enter template name of base centos 7
 
   template_name = ""

  # Provide ssh user to login
 
  ssh_user = ""

  # Provide ssh password to login

  ssh_password = ""
   
  # Enter DB password. This is local DB password of PEM monitoring server.

  db_password = ""
}  

output "PEM_SERVER_IP" {
  value = "${module.edb-pem-server.Pem-IP}"
}
