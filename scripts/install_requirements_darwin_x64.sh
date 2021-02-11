#!/bin/bash -eu

INSTALL_PATH=${INSTALL_PATH:-$HOME/.edb-cloud-tools}

TERRAFORM_ARCHIVE=https://releases.hashicorp.com/terraform/0.14.5/terraform_0.14.5_darwin_amd64.zip
GCLOUD_ARCHIVE=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-324.0.0-darwin-x86_64.tar.gz

mkdir -p ${INSTALL_PATH}
mkdir -p ${INSTALL_PATH}/bin
chown -R ${USER} ${INSTALL_PATH}

# AWS CLI
mkdir -p ${INSTALL_PATH}/aws
python3 -m venv ${INSTALL_PATH}/aws
sed -i.bak 's/$1/${1:-}/' ${INSTALL_PATH}/aws/bin/activate
source ${INSTALL_PATH}/aws/bin/activate
pip3 install awscli
deactivate
ln -sf ${INSTALL_PATH}/aws/bin/aws ${INSTALL_PATH}/bin/.

# Azure CLI
mkdir -p ${INSTALL_PATH}/azure
python3 -m venv ${INSTALL_PATH}/azure
sed -i.bak 's/$1/${1:-}/' ${INSTALL_PATH}/azure/bin/activate
source ${INSTALL_PATH}/azure/bin/activate
pip3 install azure-cli
deactivate
ln -sf ${INSTALL_PATH}/azure/bin/az ${INSTALL_PATH}/bin/.

# GCloud CLI
curl ${GCLOUD_ARCHIVE} --output /tmp/google-cloud-sdk.tar.gz
tar xvzf /tmp/google-cloud-sdk.tar.gz -C ${INSTALL_PATH}
rm /tmp/google-cloud-sdk.tar.gz
ln -sf ${INSTALL_PATH}/google-cloud-sdk/bin/gcloud ${INSTALL_PATH}/bin/.

# Ansible & ansible-galaxy
mkdir -p ${INSTALL_PATH}/ansible
python3 -m venv ${INSTALL_PATH}/ansible
sed -i.bak 's/$1/${1:-}/' ${INSTALL_PATH}/ansible/bin/activate
source ${INSTALL_PATH}/ansible/bin/activate
pip3 install ansible
deactivate
ln -sf ${INSTALL_PATH}/ansible/bin/ansible ${INSTALL_PATH}/bin/.
ln -sf ${INSTALL_PATH}/ansible/bin/ansible-galaxy ${INSTALL_PATH}/bin/.
ln -sf ${INSTALL_PATH}/ansible/bin/ansible-playbook ${INSTALL_PATH}/bin/.
ln -sf ${INSTALL_PATH}/ansible/bin/ansible-inventory ${INSTALL_PATH}/bin/.

# Terraform
mkdir -p ${INSTALL_PATH}/terraform/bin
curl ${TERRAFORM_ARCHIVE} --output /tmp/terraform.zip
unzip /tmp/terraform.zip -d ${INSTALL_PATH}/terraform/bin
ln -sf ${INSTALL_PATH}/terraform/bin/terraform ${INSTALL_PATH}/bin/.

echo "export PATH=\$PATH:${INSTALL_PATH}/bin" >> ~/.bashrc

echo
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Installation completed in ${INSTALL_PATH}/bin"
echo ""
echo "Please run this command to update the PATH variable in the current session:"
echo "   source ~/.bashrc"
