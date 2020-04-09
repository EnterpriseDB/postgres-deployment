variable aws_bucket_name {}
variable project_tags {}

resource "aws_s3_bucket" "edb-bucket" {
  bucket = var.aws_bucket_name
  acl    = "private"
  tags   = var.project_tags
}
