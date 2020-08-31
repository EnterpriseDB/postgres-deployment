#! /bin/bash
# Installation of dependent packages
if cat /etc/*release | grep ^NAME | grep Ubuntu; then
  sudo apt -y install curl
  sudo apt -y install wget
fi

if cat /etc/*release | grep ^NAME | grep Debian; then
  sudo apt -y install curl
  sudo apt -y install wget
fi 

if cat /etc/*release | grep ^NAME | grep CentOS; then
  sudo yum -y install curl 
  sudo yum -y install wget
fi

if cat /etc/*release | grep ^NAME | grep Red; then
  sudo yum -y install curl 
  sudo yum -y install wget
fi

# Terraform
TER_VER=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')

# Download, extract and move package
wget https://releases.hashicorp.com/terraform/"${TER_VER}"/terraform_"${TER_VER}"_linux_amd64.zip
unzip terraform_"${TER_VER}"_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Ansible 2.9
if cat /etc/*release | grep ^NAME | grep Ubuntu; then
   sudo apt -y update
   sudo apt -y install software-properties-common
   sudo apt-add-repository --yes --update ppa:ansible/ansible
   sudo apt -y install ansible
fi

if cat /etc/*release | grep ^NAME | grep Debian; then
   echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main" | sudo tee -a /etc/apt/sources.list
   sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
   sudo apt update
   sudo apt install ansible -y
fi

if cat /etc/*release | grep ^NAME | grep CentOS; then
   sudo yum -y update
   sudo yum -y install epel-release
   sudo yum -y install ansible
fi

if cat /etc/*release | grep ^NAME | grep Red; then
   sudo yum -y update
   sudo subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
   sudo yum -y install ansible
fi

ansible --version
