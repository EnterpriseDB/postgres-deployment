output "Pem-IP" {
  value = "${aws_instance.EDB_Pem_Server.public_ip}"
}

