variable "add_hosts_filename" {}
variable "ansible_inventory_yaml_filename" {}
variable "azure_region" {}
variable "azure_offer" {}
variable "azure_publisher" {}
variable "azure_sku" {}
variable "azuredb_passwd" {}
variable "azuredb_sku" {}
variable "cluster_name" {}
variable "network_count" {}
variable "pem_server" {}
variable "dbt2" {}
variable "dbt2_client" {}
variable "dbt2_driver" {}
variable "hammerdb_server" {}
variable "hammerdb" {}
variable "postgres_server" {}
variable "pg_version" {}
variable "project_tags" {}
variable "resourcegroup_name" {}
variable "securitygroup_name" {}
variable "ssh_priv_key" {}
variable "ssh_pub_key" {}
variable "ssh_user" {}
variable "vnet_name" {}
variable "guc_effective_cache_size" {}
variable "guc_max_wal_size" {}

resource "azurerm_subnet" "all_subnet" {
  count                = var.network_count
  name                 = format("%s-%s-%s", var.cluster_name, "edb_subnet", count.index)
  resource_group_name  = var.resourcegroup_name
  virtual_network_name = var.vnet_name
  address_prefix       = "10.0.${count.index}.0/24"
}

resource "azurerm_public_ip" "postgres_public_ip" {
  count               = var.postgres_server["count"]
  name                = format("pg-%s-%s-%s", var.cluster_name, "edb_public_ip", count.index)
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "postgres_public_nic" {
  count               = var.postgres_server["count"]
  name                = format("pg-%s-%s-%s", var.cluster_name, "edb_public_nic", count.index)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  ip_configuration {
    name      = "PG_Private_Nic_${count.index}"
    subnet_id = element(azurerm_subnet.all_subnet.*.id, count.index)

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.postgres_public_ip.*.id, count.index)
  }
}

resource "azurerm_public_ip" "dbt2_client_public_ip" {
  count               = var.dbt2_client["count"]
  name                = format("dbt2c-%s-%s-%s", var.cluster_name, "edb_public_ip", count.index)
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "dbt2_client_public_nic" {
  count               = var.dbt2_client["count"]
  name                = format("dbt2c-%s-%s-%s", var.cluster_name, "edb_public_nic", count.index)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  ip_configuration {
    name      = "DBT2_Client_Private_Nic_${count.index}"
    subnet_id = element(azurerm_subnet.all_subnet.*.id, count.index)

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.dbt2_client_public_ip.*.id, count.index)
  }
}

resource "azurerm_public_ip" "dbt2_driver_public_ip" {
  count               = var.dbt2_driver["count"]
  name                = format("dbt2d-%s-%s-%s", var.cluster_name, "edb_public_ip", count.index)
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "dbt2_driver_public_nic" {
  count               = var.dbt2_driver["count"]
  name                = format("dbt2d-%s-%s-%s", var.cluster_name, "edb_public_nic", count.index)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  ip_configuration {
    name      = "DBT2_Driver_Private_Nic_${count.index}"
    subnet_id = element(azurerm_subnet.all_subnet.*.id, count.index)

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.dbt2_driver_public_ip.*.id, count.index)
  }
}

resource "azurerm_public_ip" "hammerdb_public_ip" {
  count               = var.hammerdb_server["count"]
  name                = format("hammerdb-%s-%s-%s", var.cluster_name, "edb_public_ip", count.index)
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "hammerdb_public_nic" {
  count               = var.hammerdb_server["count"]
  name                = format("hammerdb-%s-%s-%s", var.cluster_name, "edb_public_nic", count.index)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  ip_configuration {
    name      = "HammerDB_Private_Nic_${count.index}"
    subnet_id = element(azurerm_subnet.all_subnet.*.id, count.index)

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.hammerdb_public_ip.*.id, count.index)
  }
}

resource "azurerm_public_ip" "pem_public_ip" {
  count               = var.pem_server["count"]
  name                = format("pem-%s-%s-%s", var.cluster_name, "edb_public_ip", count.index)
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "pem_public_nic" {
  count               = var.pem_server["count"]
  name                = format("pem-%s-%s-%s", var.cluster_name, "edb_public_nic", count.index)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  ip_configuration {
    name      = "PEM_Private_Nic_${count.index}"
    subnet_id = element(azurerm_subnet.all_subnet.*.id, count.index)

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.pem_public_ip.*.id, count.index)
  }
}

resource "azurerm_linux_virtual_machine" "postgres_server" {
  count               = var.postgres_server["count"]
  name                = (count.index == 0 ? format("%s-%s", var.cluster_name, "primary") : format("%s-%s%s", var.cluster_name, "standby", count.index))
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  size           = var.postgres_server["instance_type"]
  admin_username = var.ssh_user

  network_interface_ids = [element(azurerm_network_interface.postgres_public_nic.*.id, count.index)]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_pub_key)
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.azure_publisher
    offer     = var.azure_offer
    sku       = var.azure_sku

    version = "latest"
  }

  os_disk {
    name                 = format("pg-%s-%s-%s", var.cluster_name, "EDB-VM-OS-Disk", count.index)
    storage_account_type = var.postgres_server["volume"]["storage_account_type"]
    caching              = "ReadWrite"
  }

  additional_capabilities {
    ultra_ssd_enabled = true
  }

  tags = var.project_tags
}

resource "azurerm_linux_virtual_machine" "hammerdb_server" {
  count               = var.hammerdb_server["count"]
  name                = format("%s-%s%s", var.cluster_name, "hammerdbserver", count.index + 1)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  size           = var.hammerdb_server["instance_type"]
  admin_username = var.ssh_user

  network_interface_ids = [element(azurerm_network_interface.hammerdb_public_nic.*.id, count.index)]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_pub_key)
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.azure_publisher
    offer     = var.azure_offer
    sku       = var.azure_sku

    version = "latest"
  }

  os_disk {
    name                 = format("hammerdb-%s-%s-%s", var.cluster_name, "EDB-VM-OS-Disk", count.index)
    storage_account_type = var.hammerdb_server["volume"]["storage_account_type"]
    caching              = "ReadWrite"
  }

  tags = var.project_tags
}

resource "azurerm_linux_virtual_machine" "pem_server" {
  count               = var.pem_server["count"]
  name                = format("%s-%s%s", var.cluster_name, "pemserver", count.index + 1)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  size           = var.pem_server["instance_type"]
  admin_username = var.ssh_user

  network_interface_ids = [element(azurerm_network_interface.pem_public_nic.*.id, count.index)]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_pub_key)
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.azure_publisher
    offer     = var.azure_offer
    sku       = var.azure_sku

    version = "latest"
  }

  os_disk {
    name                 = format("pem-%s-%s-%s", var.cluster_name, "EDB-VM-OS-Disk", count.index)
    storage_account_type = var.pem_server["volume"]["storage_account_type"]
    caching              = "ReadWrite"
  }

  tags = var.project_tags
}

resource "azurerm_postgresql_server" "postgresql_server" {
  name                = format("%s-server", var.cluster_name)
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name

  administrator_login          = "postgres"
  administrator_login_password = var.azuredb_passwd

  sku_name = var.azuredb_sku
  version  = var.pg_version

  storage_profile {
    storage_mb            = var.postgres_server["size"]
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  ssl_enforcement = "Disabled"

  tags = var.project_tags
}

resource "azurerm_postgresql_database" "postgresql_db" {
  name                = format("%s-database", var.cluster_name)
  resource_group_name = var.resourcegroup_name
  server_name         = azurerm_postgresql_server.postgresql_server.name
  charset             = "utf8"
  collation           = "C"
}

resource "azurerm_postgresql_firewall_rule" "postgresql-fw-rule" {
  name                = format("%s-database-fw", var.cluster_name)
  resource_group_name = var.resourcegroup_name
  server_name         = azurerm_postgresql_server.postgresql_server.name
  start_ip_address    = azurerm_public_ip.hammerdb_public_ip[0].ip_address
  end_ip_address      = azurerm_public_ip.hammerdb_public_ip[0].ip_address
}

resource "azurerm_postgresql_configuration" "effective_cache_size" {
  name                = "effective_cache_size"
  resource_group_name = var.resourcegroup_name
  server_name         = azurerm_postgresql_server.postgresql_server.name
  value               = var.guc_effective_cache_size
}

resource "azurerm_postgresql_configuration" "max_wal_size" {
  name                = "max_wal_size"
  resource_group_name = var.resourcegroup_name
  server_name         = azurerm_postgresql_server.postgresql_server.name
  value               = var.guc_max_wal_size
}

resource "azurerm_linux_virtual_machine" "dbt2_client_server" {
  count               = var.dbt2_client["count"]
  name                = format("%s-%s%s", var.cluster_name, "dbt2c", count.index + 1)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  size           = var.dbt2_client["instance_type"]
  admin_username = var.ssh_user

  network_interface_ids = [element(azurerm_network_interface.dbt2_client_public_nic.*.id, count.index)]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_pub_key)
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.azure_publisher
    offer     = var.azure_offer
    sku       = var.azure_sku

    version = "latest"
  }

  os_disk {
    name                 = format("dbt2c-%s-%s-%s", var.cluster_name, "EDB-VM-OS-Disk", count.index)
    storage_account_type = var.dbt2_client["volume"]["storage_account_type"]
    caching              = "ReadWrite"
  }

  tags = var.project_tags
}

resource "azurerm_linux_virtual_machine" "dbt2_driver_server" {
  count               = var.dbt2_driver["count"]
  name                = format("%s-%s%s", var.cluster_name, "dbt2d", count.index + 1)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_region

  size           = var.dbt2_driver["instance_type"]
  admin_username = var.ssh_user

  network_interface_ids = [element(azurerm_network_interface.dbt2_driver_public_nic.*.id, count.index)]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_pub_key)
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.azure_publisher
    offer     = var.azure_offer
    sku       = var.azure_sku

    version = "latest"
  }

  os_disk {
    name                 = format("dbt2d-%s-%s-%s", var.cluster_name, "EDB-VM-OS-Disk", count.index)
    storage_account_type = var.dbt2_driver["volume"]["storage_account_type"]
    caching              = "ReadWrite"
  }

  tags = var.project_tags
}