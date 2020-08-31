#! /bin/bash

read -r -e -p "Would you like to: Setup GCP Prerequisites? Enter Yes or No:  " RESPONSE
if [ "$RESPONSE" == "Yes" ] || [ "$RESPONSE" == "yes" ] || [ "$RESPONSE" == "YES" ] 
then
  read -r -e -p "Please provide OS name and version from: 'CentOS7' 'RHEL7': " OS
  read -r -e -p "Please provide Project ID: " PROJECTID
  read -r -e -p "Please provide target GCP Location, examples: 'us-central1','us-east1', 'us-east4', 'us-west1', 'us-west2', 'us-west3' and 'us-west4': " REGION 
  read -r -e -p "Please provide how many GCP VMs to create, example '>=3': " INSTANCE_COUNT
  read -r -e -p "Provide: Absolute path of credentials json file, example: '~/accounts.json': " CREDENTIALSFILELOCATION
  read -r -e -p "Provide: Absolute path of key file, example: '~/.ssh/id_rsa.pub': " KEYFILEPATHNAMEANDEXTENSION

  echo "Creating Prerequisite Resources..."
  cd 01-prereqs-terraform || exit
  
  if [ -z "$OS" ] || [ -z "$PROJECTID" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_COUNT" ] || [ -z "$CREDENTIALSFILELOCATION" ] || [ -z "$KEYFILEPATHNAMEANDEXTENSION" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi
  
  if [ "$OS" == "CentOS7" ]
  then  
    #OSVERSION="centos-7-v20170816"
    OSVERSION="centos-7-v20200403"
  fi

  if [ "$OS" == "RHEL7" ]
  then
    OSVERSION="rhel-7-v20200403"
  fi

  terraform init
  terraform apply -auto-approve -var="os=$OSVERSION" -var="project_name=$PROJECTID" -var="subnetwork_region=$REGION" -var="instance_count=$INSTANCE_COUNT" -var="credentials=$CREDENTIALSFILELOCATION" -var="ssh_key_location=$KEYFILEPATHNAMEANDEXTENSION"
  
  if [ "$?" = "0" ]; then
    # Wait for VMs to be fully available
    echo -e '\nWaiting for VMs to be available...'
    sleep 20s
    echo 'VMs are available!'  
  fi

fi
