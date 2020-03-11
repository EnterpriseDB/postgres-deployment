###### Mandatory Fields in this config file #####

### region_name
### instance_type
### ssh_keypair   
### ssh_key_path
### subnet_id
### vpc_id 
### replication_password
### s3bucket
#############################################

### Optional Field in this config file

### EDB_yumrepo_username } Mandatory if selecting dbengine epas(all version) 
### EDB_yumrepo_password }
### iam-instance-profile
### custom_security_group_id
### replication_type } by default asynchronous
### db_user
### db_password
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


module "edb-db-cluster" {
  # The source module used for creating AWS clusters.
 
  source = "./EDB_SR_SETUP"
  
  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_password = ""

  # Enter this mandatory field which is VPC ID

  vpc_id = ""

  # Enter subnet ID where instance going to create in format ["subnetid1","subnetid2", "subnetid3"]

  subnet_id = ["subnet1", "subnet2", "subnet3"]

  # Enter AWS Instance type like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc....
 
  instance_type = ""
  
  # Enter IAM Role Name to be attached to instance. Leave blank if you are providing AWS credentials.

  iam-instance-profile = ""
 
  # Enter AWS VPC Security Group ID. If left blank new security group will create and attached to newly created instance ...
   
  custom_security_group_id = ""

  # Provide s3 bucket name followed by folder name for wal archive. Eg. s3bucket=bucketname/foldername

  s3bucket = ""

  # Enter SSH key pair name. You must create this before running this terraform config file
 
  ssh_keypair = ""

  # Provide path of ssh private file downloaded on your local system.

  ssh_key_path = ""

  # Select database engine(DB) version like pg10-postgresql version10, epas12-Enterprise Postgresql Advanced server etc..
  # DB version support V10-V12

  dbengine = ""

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
  
  db_user = ""

  # Enter custom database DB password. By default it is "postgres"

  db_password = ""
  
  # Enter replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""
  
  # Enter replication user password

  replication_password = ""
}  

output "Master-PublicIP" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "Slave1-PublicIP" {
  value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "Slave2-PublicIP" {
  value = "${module.edb-db-cluster.Slave-IP-2}"
}

output "Master-PrivateIP" {
   value = "${module.edb-db-cluster.Master-PrivateIP}"
}

output "Slave1-PrivateIP" {
  value = "${module.edb-db-cluster.Slave-1-PrivateIP}"
}

output "Slave2-PrivateIP" {
  value = "${module.edb-db-cluster.Slave-2-PrivateIP}"
}

output "Region" {
  value = "${var.region_name}" 
}

output "DBENGINE" {
  value = "${module.edb-db-cluster.DBENGINE}"
}

output "Key-Pair" {
  value = "${module.edb-db-cluster.Key-Pair}"
}

output "Key-Pair-Path" {
  value = "${module.edb-db-cluster.Key-Pair-Path}"
}

output "S3BUCKET" {
  value = "${module.edb-db-cluster.S3BUCKET}"
}
