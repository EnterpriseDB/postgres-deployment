variable "user_name" {}
variable "user_path" {}
variable "user_force_destroy" {}
variable "project_tags" {}

resource "aws_iam_user" "this" {
  name          = var.user_name
  path          = var.user_path
  force_destroy = var.user_force_destroy
  tags          = var.project_tags
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}
