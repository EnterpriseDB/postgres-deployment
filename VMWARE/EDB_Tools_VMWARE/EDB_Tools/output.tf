output "Master-IP" {
value = vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address
}
output "Slave-IP-1" {
value = vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address
}
output "Slave-IP-2" {
value = vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address
}

output "PEM-Server" {
 value = vsphere_virtual_machine.EDB_PEM_SERVER.default_ip_address
}

output "Bart-IP" {
  value = "${vsphere_virtual_machine.BART_SERVER.default_ip_address}"
}

