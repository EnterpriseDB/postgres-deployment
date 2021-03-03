#!/bin/bash -eu

TERRAFORM_VERSION="0.14.7"
GCLOUD_SDK_VERSION="329.0.0"
ANSIBLE_VERSION="2.10.7"
AWS_CLI_VERSION="1.19.18"
AZURE_CLI_VERSION="2.20.0"

INSTALL_PATH=${INSTALL_PATH:-$HOME/.edb-cloud-tools}

TERRAFORM_ARCHIVE=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
GCLOUD_ARCHIVE=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz

mkdir -p ${INSTALL_PATH}
mkdir -p ${INSTALL_PATH}/bin
chown -R ${USER} ${INSTALL_PATH}

# AWS CLI
mkdir -p ${INSTALL_PATH}/aws
python3 -m venv ${INSTALL_PATH}/aws
sed -i.bak 's/$1/${1:-}/' ${INSTALL_PATH}/aws/bin/activate
source ${INSTALL_PATH}/aws/bin/activate
python3 -m pip install "awscli==${AWS_CLI_VERSION}"
deactivate
ln -sf ${INSTALL_PATH}/aws/bin/aws ${INSTALL_PATH}/bin/.

# Azure CLI
mkdir -p ${INSTALL_PATH}/azure
python3 -m venv ${INSTALL_PATH}/azure
sed -i.bak 's/$1/${1:-}/' ${INSTALL_PATH}/azure/bin/activate
source ${INSTALL_PATH}/azure/bin/activate
# cryptography should be pinned to 3.3.2 because the next
# version introduces rust as a dependency for building it and
# breaks compatiblity with some pip versions.
# ref: https://github.com/Azure/azure-cli/issues/16858
python3 -m pip install "cryptography==3.3.2"
python3 -m pip install "azure-cli==${AZURE_CLI_VERSION}"
deactivate
ln -sf ${INSTALL_PATH}/azure/bin/az ${INSTALL_PATH}/bin/.

# GCloud CLI
wget ${GCLOUD_ARCHIVE} -O /tmp/google-cloud-sdk.tar.gz
tar xvzf /tmp/google-cloud-sdk.tar.gz -C ${INSTALL_PATH}
rm /tmp/google-cloud-sdk.tar.gz
ln -sf ${INSTALL_PATH}/google-cloud-sdk/bin/gcloud ${INSTALL_PATH}/bin/.

# Ansible & ansible-galaxy
mkdir -p ${INSTALL_PATH}/ansible
python3 -m venv ${INSTALL_PATH}/ansible
sed -i.bak 's/$1/${1:-}/' ${INSTALL_PATH}/ansible/bin/activate
source ${INSTALL_PATH}/ansible/bin/activate
python3 -m pip install "cryptography==3.3.2"
python3 -m pip install "ansible==${ANSIBLE_VERSION}"
python3 -m pip install botocore
python3 -m pip install boto3
deactivate
ln -sf ${INSTALL_PATH}/ansible/bin/ansible ${INSTALL_PATH}/bin/.
ln -sf ${INSTALL_PATH}/ansible/bin/ansible-galaxy ${INSTALL_PATH}/bin/.
ln -sf ${INSTALL_PATH}/ansible/bin/ansible-playbook ${INSTALL_PATH}/bin/.
ln -sf ${INSTALL_PATH}/ansible/bin/ansible-inventory ${INSTALL_PATH}/bin/.

# Terraform
mkdir -p ${INSTALL_PATH}/terraform/bin
wget ${TERRAFORM_ARCHIVE} -O /tmp/terraform.zip
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
