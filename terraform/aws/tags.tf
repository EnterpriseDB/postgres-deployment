# TAGS
variable "project_tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    key = "mncl_EDB_PREREQS_POSTGRES_AWS"
  }
}

variable "project_tag" {
  type    = string
  default = "mncl_EDB_PREREQS_POSTGRES_AWS_DEPLOYMENT"
}

# IAM
variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "mncl_EDB_PREREQS_POSTGRES_AWS"
}

variable "user_path" {
  description = "Desired path for AWS IAM User"
  type        = string
  default     = "/"
}

variable "user_create_iam_access_key" {
  description = "Utilized creating an IAM Access Key"
  type        = bool
  default     = true
}

variable "vpc_tag" {
  default = "mncl_EDB_PREREQS_POSTGRES_VPC"
}

# Subnets
variable "public_subnet_tag" {
  default = "mncl_EDB_PREREQS_POSTGRES_PUBLIC_SUBNET"
}

variable "vpc_id" {
  type        = string
  description = "VPC-ID"
  default     = ""
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

variable "created_by" {
  type        = string
  description = "EDB POSTGRES AWS"
  default     = "EDB POSTGRES AWS"
}

variable "sg_protocol" {
  type        = string
  description = "Protocol for Security Group"
  default     = "tcp"
}
