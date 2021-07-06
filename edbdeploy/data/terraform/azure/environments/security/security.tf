variable "securitygroup_name" {}
variable "resourcegroup_name" {}
variable "azure_region" {}
variable "project_tag" {}

resource "azurerm_network_security_group" "main" {
  name                = var.securitygroup_name
  location            = var.azure_region
  resource_group_name = var.resourcegroup_name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Port80"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Postgres"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "EDB-EPAS"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5444"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "EDB-EFM"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7800-7810"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "EDB-PEM"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgPoolII default port
  security_rule {
    name                       = "EDB-PgPoolII"
    priority                   = 800
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9999"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgPoolII default pcp port
  security_rule {
    name                       = "EDB-PgPoolPCP"
    priority                   = 801
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9898"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgPoolII default watchdog port
  security_rule {
    name                       = "EDB-PoolWatchDog"
    priority                   = 700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgPoolII default watchdog heart beat port
  security_rule {
    name                       = "EDB-PgPoolWDH"
    priority                   = 802
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9694"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgPoolII default pcp udp port
  security_rule {
    name                       = "EDB-PgPoolPCPUDP"
    priority                   = 803
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "9898"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgPoolII default watchdog udp port
  security_rule {
    name                       = "EDB-PoolWatchDogUDP"
    priority                   = 701
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgPoolII default watchdog heart udp beat port
  security_rule {
    name                       = "EDB-PgPoolWDHUDP"
    priority                   = 804
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "9694"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // PgBouncer default port
  security_rule {
    name                       = "EDB-PgBouncer"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = var.project_tag
  }
}
