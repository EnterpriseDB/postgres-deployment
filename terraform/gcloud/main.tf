module "network" {
  source = "./environments/network"

  instance_name     = var.instance_name
  network_name      = var.network_name
  subnetwork_region = var.subnetwork_region
  ip_cidr_range     = var.ip_cidr_range

}

module "security" {
  source = "./environments/security"

  network_name  = var.instance_name
  source_ranges = var.source_ranges

  depends_on = [module.network]

}

module "compute" {
  source = "./environments/compute"

  instance_count                      = var.instance_count
  pem_instance_count                  = var.pem_instance_count
  synchronicity                       = var.synchronicity
  instance_name                       = var.instance_name
  vm_type                             = var.vm_type
  vm_disk_type                        = var.vm_disk_type
  vm_disk_size                        = var.vm_disk_size
  volume_count                        = var.volume_count
  volume_disk_type                    = var.volume_disk_type
  volume_disk_size                    = var.volume_disk_size
  network_name                        = var.instance_name
  subnetwork_name                     = "${var.instance_name}-subnetwork-${var.subnetwork_region}"
  subnetwork_region                   = var.subnetwork_region
  os                                  = var.os
  ssh_user                            = var.ssh_user
  ssh_key_location                    = var.ssh_key_location
  ansible_pem_inventory_yaml_filename = var.ansible_pem_inventory_yaml_filename
  os_csv_filename                     = var.os_csv_filename
  add_hosts_filename                  = var.add_hosts_filename
  full_private_ssh_key_path           = var.full_private_ssh_key_path

  depends_on = [module.security]
}
