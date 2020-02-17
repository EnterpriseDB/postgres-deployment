###### Mandatory Fields in this config file #####
### instance_type
### subnet_id
### vpc_id 
### EDB_yumrepo_username
### EDB_yumrepo_password
### replication_password 
### db_password
#############################################

### Optional Field in this config file
### iam-instance-profile
### custom_security_group_id
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

variable "region_name" {
   description = "AWS Region Code like us-east-1,us-west-1"
   type = string
}

provider "aws" {
  region     = var.region_name
}

module "edb-expand-db-cluster" {
  # The source module to be used.
  
  source = "./EDB_ADD_REPLICA"
  
  # Enter EDB yum repository credentials for usage of any EDB tools. 

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for usage of any EDB tools.

  EDB_yumrepo_password = ""

  # Enter VPC ID.

  vpc_id = ""

  # Enter subnet ID where instance going to create

  subnet_id = ""

  # Enter AWS Instance type like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc....
 
  instance_type = ""
  
  # Enter IAM Role Name to be attached to instance. Leave blank if you are providing AWS credentials.

  iam-instance-profile = ""
 
  # Enter AWS VPC Security Group ID. If left blank new security group will create and attached to newly created instance.
   
  custom_security_group_id = ""

  # Select replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""
  
  # Enter replication user password

  replication_password = ""

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
 
  db_user = ""

 # Enter EFM notification email address

 notification_email_address = ""

 # Enter EFM role password

  efm_role_password = ""

 # Enter Password of PEM WEB UI 
 
  pem_web_ui_password = "" 

 # Enter DB password of remote server.

  db_password = ""  
}  

output "Slave-PublicIP" {
  value = "${module.edb-expand-db-cluster.Slave-PublicIP}"
}

