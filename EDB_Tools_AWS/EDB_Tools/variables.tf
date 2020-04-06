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

variable "efm_role_password" { 
   description = "Provide efm role password"
   type = string
}

variable "notification_email_address" {
   description = "Provide notification email address"
   type = string
}

variable "db_password_pem" {
   description = "Provide pem server DB password"
   type = string
}


variable "instance_type_pem" {
   description = "Provide instance type for pem server"
   type = string
}

variable "ssh_keypair_pem" {
   description = "Provide ssh keypair for pemserver"
   type = string
}

variable "subnet_id_pem" {
   description = "Provide subnet ID for pem server"
   type = string
}

variable "ssh_key_path_pem" {
   description = "Provide ssh key path for pem server"
   type = string
}


variable "custom_security_group_id_pem" {
   description = "Provide custom security group"
   type = string
}    

variable "subnet_id_bart" {
  type        = string
  description = "The subnet-id to use for instance creation."
}

variable "instance_type_bart" {
  description = "The type of instances to create."
  default     = "c4.xlarge"
  type        = string
}

variable "custom_security_group_id_bart" {
  description = "Security group to assign to the instances. Example: 'sg-12345'."
  type        = string
  default     = ""
}

variable "ssh_keypair_bart" {
  description = "The SSH key pair name"
  type = string
}

variable "ssh_key_path_bart" {
  description = "SSH private key path from local machine"
  type = string
}

variable "retention_period" {
   description = "Enter retension period"
   default = ""
   type = string
}

variable "size" {
   description = "Enter size of volume for bart backup"
   type = number
}

variable "cluster_name" {
   description = "Provide cluster name"
   type = string
}

