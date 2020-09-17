variable "instance_count" {}
variable "pem_instance_count" {}
variable "synchronicity" {}
variable "cluster_name" {}
variable vnet_name {}
variable resourcegroup_name {}
variable securitygroup_name {}
variable azure_location {}
variable ssh_key_path {}
variable project_tags {}
variable publisher {}
variable offer {}
variable sku {}
variable admin_username {}
variable ansible_inventory_yaml_filename {}
variable ansible_pem_inventory_yaml_filename {}
variable os_csv_filename {}
variable add_hosts_filename {}


resource "azurerm_subnet" "subnet" {
  count = var.instance_count
  name  = "EDB-PREREQS-SUBNET-${count.index}"
  #resource_group_name = data.azurerm_resource_group.main.name
  resource_group_name  = var.resourcegroup_name
  virtual_network_name = var.vnet_name
  address_prefix       = "10.0.${count.index}.0/24"
}

resource "azurerm_public_ip" "publicip" {
  count    = var.instance_count
  name     = "EDB-PREREQS-PUBLIC-IP-${count.index}"
  location = var.azure_location
  #resource_group_name = data.azurerm_resource_group.main.name
  resource_group_name = var.resourcegroup_name
  allocation_method   = "Static"

  #tags {
  #  group = var.project_tag
  #}
}

resource "azurerm_network_interface" "Public_Nic" {
  count = var.instance_count
  name  = "EDB-PREREQS-PUBLIC-NIC-${count.index}"
  #resource_group_name = data.azurerm_resource_group.main.name
  resource_group_name = var.resourcegroup_name
  location            = var.azure_location
  #network_security_group_id = data.azurerm_network_security_group.main.id

  ip_configuration {
    name      = "Private_Nic_${count.index}"
    subnet_id = "${element(azurerm_subnet.subnet.*.id, count.index)}"
    #subnet_id                     = "azurerm_subnet.subnet${count.index}"

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.publicip.*.id, count.index)}"
    #public_ip_address_id          = "azurerm_public_ip.publicip${count.index}"

  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count = var.instance_count
  #name                  = "EDB-VM-${count.index}"
  name                = var.pem_instance_count == 0 ? (count.index == 0 ? format("%s%s", var.cluster_name, "primary") : format("%s%s%s", var.cluster_name, "standby", count.index)) : (count.index > 1 ? format("%s%s%s", var.cluster_name, "standby", count.index) : (count.index == 0 ? format("%s%s", var.cluster_name, "pemserver") : format("%s%s", var.cluster_name, "primary")))
  resource_group_name = var.resourcegroup_name
  location            = var.azure_location
  size                = "Standard_A1"
  #size                  = "Standard_A8_v2"
  admin_username        = var.admin_username
  network_interface_ids = ["${element(azurerm_network_interface.Public_Nic.*.id, count.index)}"]
  #network_interface_ids = ["${element(azurerm_network_interface.Public_Nic.*.id, count.index < 3 ? count.index : 2)}"]

  admin_ssh_key {
    username   = "centos"
    public_key = file(var.ssh_key_path)
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    # CentOS7
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku

    version = "latest"
  }

  os_disk {
    name                 = "EDB-VM-OS-Disk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = var.project_tags
}
