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
  type        = string
  description = "VPC-ID"
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
  description = "Security Group assign to the instances. Example: 'sg-12345'."
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "IAM role name to be attached instance"
  default     = ""
  type        = string
}

variable "ssh_keypair" {
  description = "The SSH key pair name"
  type        = string
}

variable "ssh_key_path" {
  description = "SSH private key path from local machine"
  type        = string
}


variable "db_engine" {
  description = "DBEngine from pg10, pg11, pg12, epas10, epas11, epas12"
  type        = string
  default     = "pg12"
}

variable "replication_type" {
  description = "Replication type 'asynchronous' or 'synchronous'"
  type        = string
  default     = "asynchronous"
}

variable "replication_password" {
  description = "Replication Password"
  type        = string
}

variable "db_user" {
  description = "Optional DB User Name"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Custom DB Password"
  type        = string
  default     = "postgres"
}

variable "s3bucket" {
  description = "S3 bucket name for wal archive followed by folder name"
  type        = string
}

variable "created_by" {
  type        = string
  description = "EDB POSTGRES AWS"
  default     = "EDB POSTGRES AWS - Terraform"
}

variable "sg_protocol" {
  type        = string
  description = "Protocol for Security Group"
  default     = "tcp"
}

variable "public_cidr_block" {
  type        = string
  description = "Public CIDR Block"
  default     = "0.0.0.0/0"
}
