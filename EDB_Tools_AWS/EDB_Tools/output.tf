output "Master-IP" {
value = aws_eip.master-ip.public_ip
}
output "Slave-IP-1" {
value = aws_instance.EDB_DB_Cluster[1].public_ip
}
output "Slave-IP-2" {
value = aws_instance.EDB_DB_Cluster[2].public_ip
}


output "PEM-Server" {
value = aws_instance.EDB_Pem_Server.public_ip
}

output "PEM-Agent1" {
value = aws_eip.master-ip.public_ip
}

output "PEM-Agent2" {
value = aws_instance.EDB_DB_Cluster[1].public_ip
}


output "PEM-Agent3" {
value = aws_instance.EDB_DB_Cluster[1].public_ip
}

output "Bart_SERVER_IP" {
value = aws_instance.EDB_Bart_Server.public_ip
}  

output "EFM-Cluster" {
value = "${join(",", aws_instance.EDB_DB_Cluster.*.private_ip)}"
}

