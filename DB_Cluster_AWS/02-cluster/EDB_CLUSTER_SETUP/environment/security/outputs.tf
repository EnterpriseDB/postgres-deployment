output "aws_security_group_edb_sg" {
  value = aws_security_group.edb_sg.*.id
}
