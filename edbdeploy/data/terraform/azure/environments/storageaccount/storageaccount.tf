variable "storageaccount_name" {}
variable "storagecontainer_name" {}
variable "resourcegroup_name" {}
variable "azure_region" {}
variable "project_tags" {}


resource "azurerm_storage_account" "storage" {
  name                     = var.storageaccount_name
  resource_group_name      = var.resourcegroup_name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "Storage"

  tags = var.project_tags
}
