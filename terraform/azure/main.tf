module "resourcegroup" {
  source = "./environments/resourcegroup"

  resourcegroup_name = var.resourcegroup_name
  resourcegroup_tag  = var.resourcegroup_tag
  azure_location     = var.azure_location
}

module "security" {
  source = "./environments/security"

  securitygroup_name = var.securitygroup_name
  resourcegroup_name = var.resourcegroup_name
  azure_location     = var.azure_location
  project_tag        = var.project_tag

  depends_on = [module.resourcegroup]
}

module "network" {
  source = "./environments/network"

  securitygroup_name = var.securitygroup_name
  resourcegroup_name = var.resourcegroup_name
  azure_location     = var.azure_location
  vnet_name          = var.vnet_name
  vnet_cidr_block    = var.vnet_cidr_block

  depends_on = [module.resourcegroup]
}

module "storageaccount" {
  source = "./environments/storageaccount"

  storageaccount_name   = var.storageaccount_name
  storagecontainer_name = var.storagecontainer_name
  resourcegroup_name    = var.resourcegroup_name
  azure_location        = var.azure_location
  project_tags          = var.project_tags

  depends_on = [module.network]
}

module "storagecontainer" {
  source = "./environments/storagecontainer"

  storageaccount_name   = var.storageaccount_name
  storagecontainer_name = var.storagecontainer_name

  depends_on = [module.storageaccount]
}

module "vm" {
  source = "./environments/vm"

  instance_count                  = var.instance_count
  pem_instance_count              = var.pem_instance_count
  synchronicity                   = var.synchronicity
  cluster_name                    = var.cluster_name
  vnet_name                       = var.vnet_name
  resourcegroup_name              = var.resourcegroup_name
  securitygroup_name              = var.securitygroup_name
  azure_location                  = var.azure_location
  ssh_key_path                    = var.ssh_key_path
  project_tags                    = var.project_tags
  publisher                       = var.publisher
  offer                           = var.offer
  sku                             = var.sku
  admin_username                  = var.admin_username
  ansible_inventory_yaml_filename = var.ansible_inventory_yaml_filename
  os_csv_filename                 = var.os_csv_filename
  add_hosts_filename              = var.add_hosts_filename

  depends_on = [module.network]
}
