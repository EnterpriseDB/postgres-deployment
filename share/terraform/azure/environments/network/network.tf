variable "securitygroup_name" {}
variable "resourcegroup_name" {}
variable "azure_region" {}
variable "vnet_name" {}
variable "vnet_cidr_block" {}


resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr_block]
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name
}
