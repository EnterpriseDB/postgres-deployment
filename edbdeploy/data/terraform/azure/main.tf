module "resourcegroup" {
  source = "./environments/resourcegroup"

  resourcegroup_name = var.resourcegroup_name
  resourcegroup_tag  = var.resourcegroup_tag
  azure_region       = var.azure_region
}

module "security" {
  source = "./environments/security"

  securitygroup_name = var.securitygroup_name
  resourcegroup_name = var.resourcegroup_name
  azure_region       = var.azure_region
  project_tag        = var.project_tag

  depends_on = [module.resourcegroup]
}

module "network" {
  source = "./environments/network"

  securitygroup_name = var.securitygroup_name
  resourcegroup_name = var.resourcegroup_name
  azure_region       = var.azure_region
  vnet_name          = var.vnet_name
  vnet_cidr_block    = var.vnet_cidr_block

  depends_on = [module.resourcegroup]
}

module "storageaccount" {
  source = "./environments/storageaccount"

  storageaccount_name   = var.storageaccount_name
  storagecontainer_name = var.storagecontainer_name
  resourcegroup_name    = var.resourcegroup_name
  azure_region          = var.azure_region
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

  barman                              = var.barman
  postgres_server                     = var.postgres_server
  pem_server                          = var.pem_server
  hammerdb_server                     = var.hammerdb_server
  barman_server                       = var.barman_server
  pooler_server                       = var.pooler_server
  replication_type                    = var.replication_type
  cluster_name                        = var.cluster_name
  vnet_name                           = var.vnet_name
  resourcegroup_name                  = var.resourcegroup_name
  securitygroup_name                  = var.securitygroup_name
  azure_region                        = var.azure_region
  ssh_pub_key                         = var.ssh_pub_key
  ssh_priv_key                        = var.ssh_priv_key
  project_tags                        = var.project_tags
  azure_publisher                     = var.azure_publisher
  azure_offer                         = var.azure_offer
  azure_sku                           = var.azure_sku
  ssh_user                            = var.ssh_user
  ansible_inventory_yaml_filename     = var.ansible_inventory_yaml_filename
  add_hosts_filename                  = var.add_hosts_filename
  pooler_type                         = var.pooler_type
  pooler_local                        = var.pooler_local
  hammerdb                            = var.hammerdb
  network_count                       = var.pooler_server["count"] > var.postgres_server["count"] ? var.pooler_server["count"] : var.postgres_server["count"]
  depends_on = [module.network]
}
