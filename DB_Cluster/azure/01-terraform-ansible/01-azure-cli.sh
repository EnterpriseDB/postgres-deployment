#! /bin/bash

# Azure CLI Installation
# Single line install
# Does not work for Ubuntu 20.04
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install dependent packages
if cat /etc/*release | grep ^NAME | grep Ubuntu | grep Debian; then
   sudo apt-get -y update
   sudo apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg
fi

if cat /etc/*release | grep ^NAME | grep CentOS | grep Red; then
   sudo yum update -y
   sudo yum install ca-certificates curl apt-transport-https lsb-release gnupg -y
fi

# Download Microsoft signing key
if cat /etc/*release | grep ^NAME | grep Ubuntu | grep Debian; then
   curl -sL https://packages.microsoft.com/keys/microsoft.asc |
      gpg --dearmor |
      sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
fi

if cat /etc/*release | grep ^NAME | grep CentOS | grep Red; then
   sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
fi

# Add Azure CLI Repository
AZ_REPO=$(lsb_release -cs)
if cat /etc/*release | grep ^NAME | grep Ubuntu | grep Debian; then
   echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
fi

if cat /etc/*release | grep ^NAME | grep CentOS | grep Red; then
   sudo sh -c 'echo -e "[azure-cli]
     name=Azure CLI
     baseurl=https://packages.microsoft.com/yumrepos/azure-cli
     enabled=1
     gpgcheck=1
     gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
fi

# Install Azure CLI
if cat /etc/*release | grep ^NAME | grep Ubuntu | grep Debian; then
   sudo apt-get -y update
   sudo apt-get -y install azure-cli
fi

if cat /etc/*release | grep ^NAME | grep CentOS | grep Red; then
   sudo yum install azure-cli -y
fi
