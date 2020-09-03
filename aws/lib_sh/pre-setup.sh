#! /bin/bash

if [ -z "$1" ] 
then
  read -r -e -p "Please provide Project File Name : " PROJECTFILENAME
  read -r -e -p "Please provide OS name from 'CentOS7' or 'RHEL7': " OSNAME
  read -r -e -p "Please provide target AWS Region, examples: 'us-east1', 'us-west-1'or 'us-west-2':  " REGION
  read -r -e -p "Please provide how many AWS EC2 Instances to create, example '>=3': " INSTANCE_COUNT
  read -r -e -p "Please indicate if you would like a PEM Server Instance, Yes or No: : " PEMSERVER
  read -r -e -p "Provide: Name of pem file with no extension, example: 'mypemfile' : " PEMFILENAME
  read -r -e -p "Provide: Absolute path of pem file, example: '~/mypemfile.pem': " PEMFILEPATHNAMEANDEXTENSION

 
  if [ -z "$PROJECTFILENAME" ] || [ -z "$OSNAME" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_COUNT" ] || [ -z "$PEMFILENAME" ] || [ -z "$PEMFILEPATHNAMEANDEXTENSION" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi

  if ! [[ "$INSTANCE_COUNT" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
    echo 'Instance Count is not a number , please try again!' 
    exit 0 
  fi

  if ! [[ "$INSTANCE_COUNT" -gt 2 ]]; then
    echo 'Instance Count cannot be less than 3 , please try again!' 
    exit 0 
  fi

  PEM_INSTANCE_COUNT=$((0))
  if [ "$PEMSERVER" == "Yes" ] || [ "$PEMSERVER" == "yes" ]; then
    INSTANCE_COUNT=$((INSTANCE_COUNT+1))
    PEM_INSTANCE_COUNT=$((1))    
  else
    INSTANCE_COUNT=$((0))
  fi

  echo -e "\nStoring Project File Name Settings ..."
  exec 3<> $PROJECTFILENAME.txt
    echo "os=$OSNAME" >&3
    echo "aws_region=$REGION" >&3
    echo "instance_count=$INSTANCE_COUNT" >&3
    echo "ssh_keypair=$PEMFILENAME" >&3
    echo "ssh_key_path=$PEMFILEPATHNAMEANDEXTENSION" >&3
  exec 3>&-   
  
  echo -e "\nCreating Prerequisite Resources..."
  cd 01-terraform || exit
  
  terraform init
  terraform apply -auto-approve -var="os=$OSNAME" -var="aws_region=$REGION" -var="instance_count=$INSTANCE_COUNT" -var="ssh_keypair=$PEMFILENAME" -var="ssh_key_path=$PEMFILEPATHNAMEANDEXTENSION" -var="pem_instance_count=$PEM_INSTANCE_COUNT"
  
  if [ "$?" = "0" ]; then
    # Wait for instances to be fully available
    echo -e '\nWaiting for Instances to be available...'
    aws ec2 wait instance-status-ok --region $REGION
    echo 'Instances are available!'  
  fi
else
  # Create Terraform apply variable and read file with values
  terraform="terraform apply -auto-approve "
  if [ -z "$1" ] ; then
    echo 'Entered Project File Name cannot be blank please try again!' 
    exit 0 
  else
    file="$1"
  fi
  while IFS= read line
  do
    terraform="${terraform} -var="$line""
  done <"$file"

  echo -e "\nCreating Prerequisite Resources..."
  cd 01-terraform || exit

  terraform init
  echo $terraform 
  eval $terraform
fi
