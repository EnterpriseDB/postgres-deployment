variable "cluster_name" {
  description = "The name to the cluster"
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
