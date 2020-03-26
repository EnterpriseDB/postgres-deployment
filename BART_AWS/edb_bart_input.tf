###### Mandatory Fields in this config file #####
### region_name
### instance_type
### ssh_keypair   
### ssh_key_path
### vpc_id
### subnet_id
### EDB_yumrepo_username
### EDB_yumrepo_password
### db_password 
#############################################

### Optional Field in this config file
### custom_security_group_id
### retention_period
###########################################

variable "region_name" {
   description = "AWS Region Code like us-east-1,us-west-1"
   type = string
}

provider "aws" {
  # Configure your AWS account credentials here.
  region     = var.region_name
}

module "edb-bart-server" {
  # The source module to be used.

  source = "./EDB_BART_Server"
  
  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_password = ""

  # Enter vpc id

  vpc_id = ""

  # Enter subnet ID where instance going to create
  
  subnet_id = ""

  # Enter AWS Instance type like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc....
 
  instance_type = ""
 
  # Enter AWS VPC Security Group ID. If left blank new security group will create and attached to newly created instance ...
   
  custom_security_group_id = ""

  # Enter SSH key pair name. You must create this before running this terraform config file
 
  ssh_keypair = ""

  # Provide path of ssh private file download on your local system

  ssh_key_path = ""

  # Enter DB user name

   db_user = ""

  # Enter DB password

  db_password = ""

  # Specify the retention policy for the backup. This determines when an
  #  active backup should be marked as obsolete. You can specify the retention policy either in terms of number
  #  of backup or in terms of duration (days, weeks, or months). eg 3 MONTHS or 7 DAYS or 1 WEEK
  # Leave it blank if you dont want to specify retention period.
 
  retention_period = ""

  # Provide size of volume where bart server will take back up. This is just a number. For example size = 10 
  # will creare and attach volume of size 10GB

  size =  

}  

output "Bart_SERVER_IP" {
  value = "${module.edb-bart-server.Bart-IP}"
}


