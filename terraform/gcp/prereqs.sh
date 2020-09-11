#! /bin/bash
# Installation of dependent packages
if cat /etc/*release | grep ^NAME | grep Ubuntu; then
  if ! which curl > /dev/null; then
    sudo apt -y install curl
  fi
  if ! which wget > /dev/null; then
    sudo apt -y install wget
  fi
fi

if cat /etc/*release | grep ^NAME | grep Debian; then
  if ! which curl > /dev/null; then
    sudo apt -y install curl
  fi
  if ! which wget > /dev/null; then
    sudo apt -y install wget
  fi
fi 

if cat /etc/*release | grep ^NAME | grep CentOS; then
  if ! which curl > /dev/null; then
    sudo yum -y install curl 
  fi
  if ! which wget > /dev/null; then
    sudo yum -y install wget
  fi
fi

if cat /etc/*release | grep ^NAME | grep Red; then
  if ! which curl > /dev/null; then
    sudo yum -y install curl 
  fi
  if ! which wget > /dev/null; then
    sudo yum -y install wget
  fi
fi

if ! which terraform > /dev/null; then
  # Terraform
  TER_VER=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')

  # Download, extract and move package
  wget https://releases.hashicorp.com/terraform/"${TER_VER}"/terraform_"${TER_VER}"_linux_amd64.zip
  unzip terraform_"${TER_VER}"_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
fi
terraform --version

# Ansible 2.9
if cat /etc/*release | grep ^NAME | grep Ubuntu; then
   sudo apt -y update
   sudo apt -y install software-properties-common
   sudo apt-add-repository --yes --update ppa:ansible/ansible
   if ! which ansible > /dev/null; then
     sudo apt -y install ansible
   fi
fi

if cat /etc/*release | grep ^NAME | grep Debian; then
   echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main" | sudo tee -a /etc/apt/sources.list
   sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
   sudo apt update
   if ! which ansible > /dev/null; then
     sudo apt install ansible -y
   fi
fi

if cat /etc/*release | grep ^NAME | grep CentOS; then
   sudo yum -y update
   sudo yum -y install epel-release
   if ! which ansible > /dev/null; then
     sudo yum -y install ansible
   fi
fi

if cat /etc/*release | grep ^NAME | grep Red; then
   sudo yum -y update
   sudo subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
   if ! which ansible > /dev/null; then
     sudo yum -y install ansible
   fi
fi

ansible --version
