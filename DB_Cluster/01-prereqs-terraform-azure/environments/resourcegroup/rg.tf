variable azure_location {}
variable resourcegroup_tag {}
variable resourcegroup_name {}


resource "azurerm_resource_group" "resource_group" {
  name     = var.resourcegroup_name
  location = var.azure_location

  tags = {
    Name = var.resourcegroup_tag
  }
}
