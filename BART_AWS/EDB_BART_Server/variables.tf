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

  
variable "subnet_id" {
  type        = string
  description = "The subnet-id to use for instance creation."
}


variable "ssh_user" {
  description = "The public key to use when connecting to the instances."
  type        = string
  default     = "centos"
}

variable "instance_type" {
  description = "The type of instances to create."
  default     = "c4.xlarge"
  type        = string
}

variable "custom_security_group_id" {
  description = "Security group to assign to the instances. Example: 'sg-12345'."
  type        = string
  default     = ""
}

variable "ssh_keypair" {
  description = "The SSH key pair name"
  type = string
}

variable "ssh_key_path" {
  description = "SSH private key path from local machine"
  type = string
}

variable "db_password" {
   description = "Enter DB password of remote server"
   type = string
}

variable "db_user" {
    description = "Provide DB user name"
    type = string
}

variable "vpc_id" {
   description = "Enter AWS VPC-ID"
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

variable  "bart_user" {
   description = "Provide Bart User name"
   type = string
   default = "enterprisedb"
}
   
