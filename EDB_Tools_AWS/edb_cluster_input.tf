###### Mandatory Fields in this config file #####

### region_name
### instance_type
### ssh_keypair   
### ssh_key_path
### subnet_id
### vpc_id 
### replication_password
### s3bucket
### efm_role_password
### instance_type_pem
### ssh_keypair_pem
### subnet_id_pem
### ssh_key_path_pem
### db_password_pem
### EDB_yumrepo_username
### EDB_yumrepo_password

#############################################
### iam-instance-profile
### custom_security_group_id
### replication_type } by default asynchronous
### db_user
### db_password
### cluster_name
###########################################

### Default User DB credentials##########

### For EPAS12
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
 
  source = "./EDB_Tools"
  
  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_password = ""

  # Provide Cluster name to be tagged. If you leave field blank we will use default value epas12.

  cluster_name = ""

  # Enter this mandatory field which is VPC ID

  vpc_id = ""

  # Enter subnet ID where instance going to create in format ["subnetid1","subnetid2", "subnetid3"]

  subnet_id = ["subnet-1", "subnet-2", "subnet-3"]

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


  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
  
  db_user = ""

  # Enter custom database DB password. By default it is "postgres"

  db_password = ""
  
  # Enter replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""
  
  # Enter replication user password

  replication_password = ""


  #### EFM SET UP BEGINE HERE ####

  # Provide EFM role password.

  efm_role_password = ""

  # Provide EFM notification email address to receive cluster health notification or any change in status. 

  notification_email_address = ""

 ### PEM MONITORING SERVER SETUP BEGINE HERE ###

  # Provide Instance Type for PEM monitoring server like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc.

  instance_type_pem = ""

  # Provide custom security group for pem server. Leaving it blank will create new security group.

   custom_security_group_id_pem = ""

  # Provide subnet id for pem monitoring server. Eg subnet_id_pem = "subnet-1234".

  subnet_id_pem = ""

  # Provide key pair names for PEM monitoring server. 

  ssh_keypair_pem = ""

  # Provide Key pair path for PEM monitoring server.
 
  ssh_key_path_pem = ""

  # Provide DB password for PEM monitoring server.

  db_password_pem = ""

  #### BART SERVER SET UP BEGINE HERE ##

  # Enter subnet ID where instance going to create
  
  subnet_id_bart = ""

  # Enter AWS Instance type like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc....
 
  instance_type_bart = ""
 
  # Enter AWS VPC Security Group ID. If left blank new security group will create and attached to newly created instance ...
   
  custom_security_group_id_bart = ""

  # Enter SSH key pair name. You must create this before running this terraform config file
 
  ssh_keypair_bart = ""

  # Provide path of ssh private file download on your local system

  ssh_key_path_bart = ""

  # Specify the retention policy for the backup. This determines when an
  #  active backup should be marked as obsolete. You can specify the retention policy either in terms of number
  #  of backup or in terms of duration (days, weeks, or months). eg 3 MONTHS or 7 DAYS or 1 WEEK
  # Leave it blank if you dont want to specify retention period.
 
  retention_period = ""

  # Provide size of volume where bart server will take back up. This is just a number. For example size = 10 
  # will creare and attach volume of size 10GB

  size =  
 
 
}  

output "A_Master-PublicIP" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "B_Standby1-PublicIP" {
  value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "C_Standby2-PublicIP" {
  value = "${module.edb-db-cluster.Slave-IP-2}"
}

output "D_PEM-Server" {
  value = "${module.edb-db-cluster.PEM-Server}"
}

output "E_PEM-Agent1" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "F_PEM-Agent2" {
  value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "G_PEM-Agent3" {
  value = "${module.edb-db-cluster.Slave-IP-2}"
}

output "H_Bart_SERVER_IP" {
  value = "${module.edb-db-cluster.Bart_SERVER_IP}"
}

output "I_EFM-Cluster" {
   value = "${module.edb-db-cluster.EFM-Cluster}"
}

