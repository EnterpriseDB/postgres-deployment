output "Master-IP" {
  value = vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address
}
output "Slave-IP-1" {
  value = vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address
}
output "Slave-IP-2" {
  value = vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address
}

output "DBENGINE" {
  value = var.dbengine
}

output "SSH-USER" {
  value = var.ssh_user
}

output "CLUSTER_NAME" {
  value = var.cluster_name
}

