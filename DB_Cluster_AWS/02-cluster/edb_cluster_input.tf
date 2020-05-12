###### Mandatory Fields in this config file #####

### region_name
### instance_type
### ssh_keypair_file
### ssh_key_path
### subnet_id
### vpc_id 
#############################################

### iam_instance_profile
### custom_security_group_id
###########################################

variable "region_name" {
  description = "AWS Region Code like us-east-1,us-west-1"
  type        = string
}


module "edb-db-cluster" {
  # The source module used for creating AWS clusters.
  source = "./EDB_CLUSTER_SETUP"

  # Enter name to the DB cluster. This will be used to tag the ec2 instance.

  cluster_name = "Dev"

  # Enter this mandatory field which is VPC ID
  #vpc_id = ""
  vpc_id = "vpc-de8457a4"

  # Enter subnet ID where instance going to create in format ["subnetid1","subnetid2", "subnetid3"]
  subnet_id = ["subnet-e0621bef", "subnet-cffa7da8", "subnet-cfaa2a93"]

  # Enter AWS Instance type like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc....
  # instance_type = "t2.micro"
  # instance_type = "t3.large"
  # instance_type = "c4.2xlarge"
  # instance_type = "m5.2xlarge"
  instance_type = "t2.micro"

  # Enter IAM Role Name to be attached to instance. Leave blank if you are providing AWS credentials.
  iam_instance_profile = "role-for-terraform"

  # Enter AWS VPC Security Group ID. 
  
  custom_security_group_id = "sg-004e2d4733a2757d5"

  # Enter SSH key pair name. 
  # Items to exclude: full path and file extension (.pem or .ppk)
  # Example: ssh_keypair = "<nameofkeypairfile>"
  #ssh_keypair = ""
  ssh_keypair = "ark-v1"

  # Provide path of ssh private file downloaded on your local system.
  # Include: Full path of the SSH Key Pair File, name of the SSH Key Pair File and file extension
  # Example: "/<file>.pem"
  #ssh_key_path = ""
  ssh_key_path = "/Users/edb/Documents/ark-v1.pem"

}
