provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = format("%s-%s", var.kClusterName, "RG")
  location = var.azureLocation

  tags = {
    environment = var.kEnvironmentName
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = var.kClusterName
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = format("%s-%s", var.kClusterName, "k8s")

  default_node_pool {
    name            = "default"
    node_count      = var.kNodeCount
    vm_size         = var.kVmSize
    os_disk_size_gb = var.kDiskOsSize
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = var.kEnvironmentName
  }
}
