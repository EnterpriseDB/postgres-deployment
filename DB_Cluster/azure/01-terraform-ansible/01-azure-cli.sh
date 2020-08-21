#! /bin/bash

# Azure CLI Installation
# Single line install
# Does not work for Ubuntu 20.04
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install dependent packages
sudo apt-get update
sudo apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg

# Download Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Add Azure CLI Repository
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list

# Install Azure CLI
sudo apt-get -y update
sudo apt-get -y install azure-cli
