#! /bin/bash

read -r -e -p "Would you like to: Setup AWS Prerequisites? Enter Yes or No:  " RESPONSE
if [ "$RESPONSE" == "Yes" ] || [ "$RESPONSE" == "yes" ] || [ "$RESPONSE" == "YES" ] 
then
  read -r -e -p "Please provide OS name from 'CentOS7' or 'RHEL7': " OSNAME
  read -r -e -p "Please provide target AWS Region: " REGION
  read -r -e -p "Please provide how many AWS EC2 Instances to create, example '>=3': " INSTANCE_COUNT
  read -r -e -p "Provide: Name of pem file with no extension, example: 'mypemfile' : " PEMFILENAME
  read -r -e -p "Provide: Absolute path of pem file, example: '~/mypemfile.pem': " PEMFILEPATHNAMEANDEXTENSION

  echo "Creating Prerequisite Resources..."
  cd 01-prereqs-terraform || exit
  
  if [ -z "$OSNAME" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_COUNT" ] || [ -z "$PEMFILENAME" ] || [ -z "$PEMFILEPATHNAMEANDEXTENSION" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi
  
  terraform init
  terraform apply -auto-approve -var="os=$OSNAME" -var="aws_region=$REGION" -var="instance_count=$INSTANCE_COUNT" -var="ssh_keypair=$PEMFILENAME" -var="ssh_key_path=$PEMFILEPATHNAMEANDEXTENSION"
  
  if [ "$?" = "0" ]; then
    # Wait for instances to be fully available
    echo -e '\nWaiting for Instances to be available...'
    aws ec2 wait instance-status-ok --region $REGION
    echo 'Instances are available!'  
  fi
fi
