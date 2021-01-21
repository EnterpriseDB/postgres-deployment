variable "aws_iam_user_name" {}
variable "project_tag" {}


resource "aws_iam_group" "group" {
  name = format("%s_%s", var.project_tag, "GROUP")

}

resource "aws_iam_policy" "policy" {
  name        = format("%s_%s", var.project_tag, "POLICY")
  description = format("%s_%s", var.project_tag, "POLICY")

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "edb-prereq-policy-attach" {
  name = format("%s_%s", var.project_tag, "POLICY_ATTACH")

  users      = [var.aws_iam_user_name]
  groups     = [aws_iam_group.group.name]
  policy_arn = aws_iam_policy.policy.arn
}
