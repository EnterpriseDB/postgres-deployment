data "terraform_remote_state" "SR" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster_AWS/terraform.tfstate"
  }
}


data "aws_ami" "centos_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name = "name"

    values = [
      "CentOS Linux 7 x86_64 HVM EBS *",
    ]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "aws_security_group" "edb_bart_sg" {
    count = var.custom_security_group_id == "" ? 1 : 0 
    name = "edb_bartsecurity_group"
    description = "Rule for edb-terraform-resource"
    vpc_id = var.vpc_id

    ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
}


resource "aws_instance" "EDB_Bart_Server" {
   ami = data.aws_ami.centos_ami.id
   instance_type  = var.instance_type
   key_name   = var.ssh_keypair
   subnet_id = var.subnet_id
   vpc_security_group_ids = ["${var.custom_security_group_id == "" ? aws_security_group.edb_bart_sg[0].id : var.custom_security_group_id}"]
root_block_device {
   delete_on_termination = "true"
   volume_size = "8"
   volume_type = "gp2"
}
ebs_block_device {
  delete_on_termination = "true"
  device_name = "/dev/sdf"
  volume_size = var.size
  volume_type = "gp2" 
}

tags = {
  Name = "edb-bart-server"
  Created_By = "Terraform"
}


provisioner "local-exec" {
    command = "echo '${aws_instance.EDB_Bart_Server.public_ip} ansible_ssh_private_key_file=${var.ssh_key_path}' > ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Master-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.SR.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}
provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = aws_instance.EDB_Bart_Server.public_ip 
      type = "ssh"
      user = var.ssh_user
      private_key = file(var.ssh_key_path)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/bartserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} BART_IP=${aws_instance.EDB_Bart_Server.public_ip} DB_IP=${data.terraform_remote_state.SR.outputs.Master-PublicIP} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} DB_PASSWORD=${var.db_password} DB_USER=${var.db_user} RETENTION_PERIOD=\"${var.retention_period}\"'" 
}

lifecycle {
    create_before_destroy = true
  }


}


resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
    aws_instance.EDB_Bart_Server
]
}

