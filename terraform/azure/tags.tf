# Tags
variable "project_tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    key = "newtest_EDB_PREREQS_AZURE"
  }
}

variable "project_tag" {
  type    = string
  default = "newtest_EDB_PREREQS_AZURE_DEPLOYMENT"
}

# Storage
variable "storageaccount_name" {
  description = "Name of the bucket for storing related data of deployment"
  type        = string
  default     = "newtestedbpostgres"
}

variable "storagecontainer_name" {
  description = "Name of the bucket for storing related data of deployment"
  type        = string
  default     = "newtestedbprereqsstoragecontainer"
}

# VNet
variable "vnet_name" {
  type    = string
  default = "newtest_EDB-PREREQS-VNet"
}

# Resource Group
variable "resourcegroup_tag" {
  default = "newtest_EDB-PREREQS-RESOURCEGROUP"
}

variable "resourcegroup_name" {
  default = "newtest_EDB-PREREQS-RESOURCEGROUP"
}

# Subnets
variable "subnet_name" {
  default = "newtest_EDB-PREREQS-PUBLIC-SUBNET"
}

variable "subnet_tag" {
  default = "newtest_EDB-PREREQS-PUBLIC-SUBNET"
}

# Security Group
variable "securitygroup_name" {
  default = "newtest_EDB-PREREQS-SECURITYGROUP"
}
