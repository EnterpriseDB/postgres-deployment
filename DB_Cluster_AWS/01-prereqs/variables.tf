# TAGS
variable "project_tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    key = "EDB_PREREQS_POSTGRES_AWS"
  }
}

variable "project_tag" {
  type    = string
  default = "EDB_PREREQS_POSTGRES_AWS_DEPLOYMENT"
}

# Region
variable "aws_region" {
  default = "us-west-2"
}

# IAM
variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "EDB_PREREQS_POSTGRES_AWS"
}

variable "user_name" {
  description = "Desired name for AWS IAM User"
  type        = string
  default     = "edb-test"
}

variable "user_path" {
  description = "Desired path for AWS IAM User"
  type        = string
  default     = "/"
}

variable "user_force_destroy" {
  description = "Force destroying AWS IAM User and dependencies"
  type        = bool
  default     = false
}

# S3
variable "aws_bucket_name" {
  description = "Name of the bucket for storing related data of deployment"
  type        = string
  default     = "edb-postgres"
}

variable "aws_bucket_folder" {
  description = "Folder storing EDB Postgres Deployment Folder"
  type        = string
  default     = "wal"
}

variable "user_create_iam_access_key" {
  description = "Utilized creating an IAM Access Key"
  type        = bool
  default     = true
}

# VPC
variable "public_cidrblock" {
  description = "Public CIDR block"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_cidr_block" {
  description = "CIDR Block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_tag" {
  default = "EDB_PREREQS_POSTGRES_VPC"
}

# Subnets
variable "public_subnet_tag" {
  default = "EDB_PREREQS_POSTGRES_PUBLIC_SUBNET"
}

variable "public_subnet_1_cidrblock" {
  description = "CIDR block for Public Subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidrblock" {
  description = "CIDR block for Public Subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_3_cidrblock" {
  description = "CIDR block for Public Subnet 3"
  type        = string
  default     = "10.0.3.0/24"
}
