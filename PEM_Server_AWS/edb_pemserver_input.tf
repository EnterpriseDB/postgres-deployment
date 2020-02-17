###### Mandatory Fields in this config file #####
### region_name
### instance_type
### ssh_keypair   
### ssh_key_path
### subnet_id
### EDB_yumrepo_username
### EDB_yumrepo_password
### db_password 
#############################################

### Optional Field in this config file
### custom_security_group_id

###########################################

variable "region_name" {
   description = "AWS Region Code like us-east-1,us-west-1"
   type = string
}

provider "aws" {
  region     = var.region_name
}

module "edb-pem-server" {
  # The source module to be used.

  source = "./EDB_PEM_Server"
  
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

  # Enter DB password. This is local DB password of PEM monitoring server.

  db_password = ""

}  

output "PEM_SERVER_IP" {
  value = "${module.edb-pem-server.Pem-IP}"
}


