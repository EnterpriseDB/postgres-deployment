variable securitygroup_name {}
variable resourcegroup_name {}
variable azure_location {}
variable vnet_name {}
variable vnet_cidr_block {}


resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr_block]
  location            = var.azure_location
  resource_group_name = var.resourcegroup_name
  #resource_group_name = data.azurerm_resource_group.main.name
}
