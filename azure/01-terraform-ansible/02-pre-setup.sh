#! /bin/bash

read -r -e -p "Would you like to: Setup Azure Prerequisites? Enter Yes or No:  " RESPONSE
if [ "$RESPONSE" == "Yes" ] || [ "$RESPONSE" == "yes" ] || [ "$RESPONSE" == "YES" ] 
then
  read -r -e -p "Please provide Publisher from 'OpenLogic' or 'RedHat': " PUBLISHER
  read -r -e -p "Please provide OS name from: 'Centos' or 'RHEL': " OFFER
  read -r -e -p "Please provide OS version from: Centos - '7.7' or RHEL - '7.8': " SKU
  read -r -e -p "Please provide target Azure Location, examples: 'centralus, eastus, eastus2, westus, westcentralus, westus2, northcentralus, southcentralus': " LOCATION 
  read -r -e -p "Please provide how many Azure VMs to create, example '>=3': " INSTANCE_COUNT
  read -r -e -p "Provide: Absolute path of key file, example: '~/.ssh/id_rsa.pub': " KEYFILEPATHNAMEANDEXTENSION

  echo "Creating Prerequisite Resources..."
  cd 01-prereqs-terraform || exit
  
  if [ -z "$PUBLISHER" ] || [ -z "$OFFER" ] || [ -z "$SKU" ] || [ -z "$LOCATION" ] || [ -z "$INSTANCE_COUNT" ] || [ -z "$KEYFILEPATHNAMEANDEXTENSION" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi
  
  terraform init
  terraform apply -auto-approve -var="publisher=$PUBLISHER" -var="offer=$OFFER" -var="sku=$SKU" -var="azure_location=$LOCATION" -var="instance_count=1" -var="ssh_key_path=$KEYFILEPATHNAMEANDEXTENSION"
  
  if [ "$?" = "0" ]; then
    # Wait for VMs to be fully available
    az vm wait --ids $(az vm list -g EDB-PREREQS-RESOURCEGROUP --query "[].id" -o tsv) --created
  fi

  # Execute with the correct instance count
  terraform apply -auto-approve -var="publisher=$PUBLISHER" -var="offer=$OFFER" -var="sku=$SKU" -var="azure_location=$LOCATION" -var="instance_count=$INSTANCE_COUNT" -var="ssh_key_path=$KEYFILEPATHNAMEANDEXTENSION"
  
  if [ "$?" = "0" ]; then
    # Wait for VMs to be fully available
    echo -e '\nWaiting for VMs to be available...'
    az vm wait --ids $(az vm list -g EDB-PREREQS-RESOURCEGROUP --query "[].id" -o tsv) --created
    echo 'VMs are available!'  
  fi

fi
