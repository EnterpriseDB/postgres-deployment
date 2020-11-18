# Tags
variable "project_tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    key = "c8mn_EDB_PREREQS_AZURE"
  }
}

variable "project_tag" {
  type    = string
  default = "c8mn_EDB_PREREQS_AZURE_DEPLOYMENT"
}

# Storage
variable "storageaccount_name" {
  description = "Name of the bucket for storing related data of deployment"
  type        = string
  default     = "c8mnedbpostgres"
}

variable "storagecontainer_name" {
  description = "Name of the bucket for storing related data of deployment"
  type        = string
  default     = "c8mnedbprereqsstoragecontainer"
}

# VNet
variable "vnet_name" {
  type    = string
  default = "c8mn_EDB-PREREQS-VNet"
}

# Resource Group
variable "resourcegroup_tag" {
  default = "c8mn_EDB-PREREQS-RESOURCEGROUP"
}

variable "resourcegroup_name" {
  default = "c8mn_EDB-PREREQS-RESOURCEGROUP"
}

# Subnets
variable "subnet_name" {
  default = "c8mn_EDB-PREREQS-PUBLIC-SUBNET"
}

variable "subnet_tag" {
  default = "c8mn_EDB-PREREQS-PUBLIC-SUBNET"
}

# Security Group
variable "securitygroup_name" {
  default = "c8mn_EDB-PREREQS-SECURITYGROUP"
}
