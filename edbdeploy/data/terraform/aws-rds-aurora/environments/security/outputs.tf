output "aws_security_group_id" {
  value = aws_security_group.edb-prereqs-rules.id
}

output "aws_security_group_id_rds" {
  value = aws_security_group.rds.id
}
