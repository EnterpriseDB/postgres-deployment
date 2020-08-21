#! /bin/bash
# Installation dependent packages
sudo apt -y install curl 
sudo apt -y install wget

# Terraform
TER_VER=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')

# Download, extract and move package
wget https://releases.hashicorp.com/terraform/"${TER_VER}"/terraform_"${TER_VER}"_linux_amd64.zip
unzip terraform_"${TER_VER}"_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Ansible 2.9
sudo apt update
sudo apt -y install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt -y install ansible
