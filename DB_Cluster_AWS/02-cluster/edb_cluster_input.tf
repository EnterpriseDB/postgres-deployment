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
### iam_instance_profile
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
  type        = string
}


module "edb-db-cluster" {
  # The source module used for creating AWS clusters.
  source = "./EDB_CLUSTER_SETUP"

  # Enter EDB Yum Repository Credentials for usage of any EDB tools.
  EDB_yumrepo_username = ""

  # Enter EDB Yum Repository Credentials for usage of any EDB tools.
  EDB_yumrepo_password = ""

  # Enter this mandatory field which is VPC ID
  #vpc_id = ""
  vpc_id = "vpc-07eda8ebfbf602baf"

  # Enter subnet ID where instance going to create in format ["subnetid1","subnetid2", "subnetid3"]
  subnet_id = ["subnet-0aaade8494c52c63a", "subnet-081ea42891ac9af6b", "subnet-09a1c944af4700da9"]

  # Enter AWS Instance type like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc....
  # instance_type = "t2.micro"
  # instance_type = "t3.large"
  # instance_type = "c4.2xlarge"
  # instance_type = "m5.2xlarge"
  instance_type = "t2.micro"

  # Enter IAM Role Name to be attached to instance. Leave blank if you are providing AWS credentials.
  iam_instance_profile = ""

  # Enter AWS VPC Security Group ID. 
  # If left blank new security group will create and attached to newly created instance ...
  custom_security_group_id = ""

  # Provide s3 bucket name followed by folder name for wal archive. Eg. s3bucket=bucketname/foldername
  #s3bucket = ""
  s3bucket = "edb-postgres/wal"

  # Enter SSH key pair name. You must create this before running this terraform config file
  #ssh_keypair = ""
  ssh_keypair = "/home/dortiz/test-edb-deployment-keypair.pem"

  # Provide path of ssh private file downloaded on your local system.
  #ssh_key_path = ""
  ssh_key_path = "/home/dortiz/"

  # Select database engine(DB) version like pg10-postgresql version10, epas12-Enterprise Postgresql Advanced server etc.
  # DB version support V10-V12
  # Uncomment the desired version to install
  # db_engine = "epas10"
  # db_engine = "epas11"
  # db_engine = "epas12"
  # db_engine = "pg10"
  # db_engine = "pg11"
  # db_engine = "pg12"
  db_engine = "pg12"

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
  db_user = "postgres"

  # Enter custom database DB password. By default it is "postgres"
  db_password = "postgres"

  # Enter replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".
  # replication_type = "synchronous"
  # replication_type = "asynchronous"
  replication_type = "synchronous"

  # Enter replication user password
  replication_password = "postgres"
}
