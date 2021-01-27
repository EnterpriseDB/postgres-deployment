variable "storageaccount_name" {}
variable "storagecontainer_name" {}


resource "azurerm_storage_container" "container" {
  name                  = var.storagecontainer_name
  storage_account_name  = var.storageaccount_name
  container_access_type = "private"
}
