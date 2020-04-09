# Public IPs
output "Master-IP" {
  value = aws_eip.master-ip.public_ip
}
output "Slave-IP-1" {
  value = aws_instance.EDB_DB_Cluster[1].public_ip
}
output "Slave-IP-2" {
  value = aws_instance.EDB_DB_Cluster[2].public_ip
}

# Private IPs
output "Master-PrivateIP" {
  value = aws_eip.master-ip.private_ip
}
output "Slave-1-PrivateIP" {
  value = aws_instance.EDB_DB_Cluster[1].private_ip
}
output "Slave-2-PrivateIP" {
  value = aws_instance.EDB_DB_Cluster[2].private_ip
}
