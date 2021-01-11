variable "instance_size" {}
variable "instance_count" {}
variable "instance_disktype" {}
variable "vm_manageddisk_count" {}
variable "vm_manageddisk_volume_size" {}
variable "vm_manageddisk_disktype" {}
variable "pem_instance_count" {}
variable "synchronicity" {}
variable "cluster_name" {}
variable "vnet_name" {}
variable "resourcegroup_name" {}
variable "securitygroup_name" {}
variable "azure_location" {}
variable "ssh_key_path" {}
variable "full_private_ssh_key_path" {}
variable "project_tags" {}
variable "publisher" {}
variable "offer" {}
variable "sku" {}
variable "admin_username" {}
variable "ansible_inventory_yaml_filename" {}
variable "os_csv_filename" {}
variable "add_hosts_filename" {}


resource "azurerm_subnet" "subnet" {
  count                = var.instance_count
  name                 = format("%s-%s-%s", var.cluster_name, "EDB-PREREQS-SUBNET", count.index)
  resource_group_name  = var.resourcegroup_name
  virtual_network_name = var.vnet_name
  address_prefix       = "10.0.${count.index}.0/24"
}

resource "azurerm_public_ip" "publicip" {
  count               = var.instance_count
  name                = format("%s-%s-%s", var.cluster_name, "EDB-PREREQS-PUBLIC-IP", count.index)
  location            = var.azure_location
  resource_group_name = var.resourcegroup_name
  allocation_method   = "Static"

  #tags {
  #  group = var.project_tag
  #}
}

resource "azurerm_network_interface" "Public_Nic" {
  count               = var.instance_count
  name                = format("%s-%s-%s", var.cluster_name, "EDB-PREREQS-PUBLIC-NIC", count.index)
  resource_group_name = var.resourcegroup_name
  location            = var.azure_location

  ip_configuration {
    name      = "Private_Nic_${count.index}"
    subnet_id = element(azurerm_subnet.subnet.*.id, count.index)

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.publicip.*.id, count.index)

  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.instance_count
  name                = (var.pem_instance_count == "1" && count.index == 0 ? format("%s-%s", var.cluster_name, "pemserver") : (var.pem_instance_count == "0" && count.index == 1 ? format("%s-%s", var.cluster_name, "primary") : (count.index > 1 ? format("%s-%s%s", var.cluster_name, "standby", count.index) : format("%s-%s%s", var.cluster_name, "primary", count.index))))
  resource_group_name = var.resourcegroup_name
  location            = var.azure_location

  size           = var.instance_size
  admin_username = var.admin_username

  network_interface_ids = [element(azurerm_network_interface.Public_Nic.*.id, count.index)]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key_path)
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku

    version = "latest"
  }

  os_disk {
    name                 = format("%s-%s-%s", var.cluster_name, "EDB-VM-OS-Disk", count.index)
    storage_account_type = var.instance_disktype
    caching              = "ReadWrite"
  }

  tags = var.project_tags
}

resource "azurerm_managed_disk" "managed_disk" {
  count                = var.instance_count * var.vm_manageddisk_count
  name                 = format("%s-%s-%s", var.cluster_name, "VM", count.index)
  resource_group_name  = var.resourcegroup_name
  location             = var.azure_location
  storage_account_type = var.vm_manageddisk_disktype
  create_option        = "Empty"
  disk_size_gb         = var.vm_manageddisk_volume_size
  tags                 = var.project_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attachment" {
  count              = var.instance_count * var.vm_manageddisk_count
  managed_disk_id    = azurerm_managed_disk.managed_disk.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.vm.*.id[ceil((count.index + 1) * 1.0 / var.vm_manageddisk_count) - 1]
  lun                = count.index + 10
  caching            = "ReadWrite"

  provisioner "remote-exec" {
    #script = "../../terraform/azure/environments/vm/setup_volumes.sh"
    inline = ["touch ~/test.txt"]

    connection {
      type = "ssh"
      user = var.admin_username
      host = element(azurerm_public_ip.publicip.*.ip_address, floor(count.index / var.vm_manageddisk_count))

      private_key = file(var.full_private_ssh_key_path)
    }
  }
}
