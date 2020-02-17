variable "EDB_yumrepo_username" {
  description = "yum repo user name"
  default     = ""
  type        = string
}

variable "EDB_yumrepo_password" {
  description = "yum repo user password"
  default     = ""
  type        = string
}

variable "vpc_id" {
   type    = string
   description = "Enter VPC-ID"
   default     = ""
}
  
variable "subnet_id" {
  type        = list(string)
  description = "The subnet-id to use for instance creation."
}


variable "ssh_user" {
  description = "The username who can connect to the instances."
  type        = string
  default     = "centos"
}

variable "instance_type" {
  description = "The type of instances to create."
  default     = "c4.xlarge"
  type        = string
}

variable "custom_security_group_id" {
  description = "Security group assign to the instances. Example: 'sg-12345'."
  type        = string
  default     = ""
}

variable "iam-instance-profile" {
  description = "IAM role name to be attached instance"
  default = ""
  type = string
}

variable "ssh_keypair" {
  description = "The SSH key pair name"
  type = string
}

variable "ssh_key_path" {
  description = "SSH private key path from local machine"
  type = string
}


variable "dbengine" {
   description = "Select dbengine from pg10, pg11, pg12, epas10, epas11, epas12"
   type = string
   default = "pg12"
}

variable "replication_type" {
   description = "Select replication type asynchronous or synchronous"
   type = string
   default = "asynchronous"
}

variable "replication_password" {
   description = "Enter replication password of your choice"
   type = string
}

variable "db_user" {
   description = "Enter optional DB user name"
   type = string
}

variable "db_password" {
   description = "Enter custom DB password"
   type = string
   default = "postgres"
}

variable "s3bucket" {
   description = "Enter s3 bucket name for wal archive followed by folder name"
   type = string
}    
