#! /bin/bash

if [ -z "$1" ] 
then
  read -r -e -p "Please provide Google Project ID: " PROJECTID
  read -r -e -p "Please provide target GCP Location, examples: 'us-central1','us-east1', 'us-east4', 'us-west1', 'us-west2', 'us-west3' and 'us-west4': " REGION 
  read -r -e -p "Provide: Absolute path of credentials json file, example: '~/accounts.json': " CREDENTIALSFILELOCATION
  read -r -e -p "Provide: Absolute path of key file, example: '~/.ssh/id_rsa.pub': " KEYFILEPATHNAMEANDEXTENSION
 
  if [ -z "$PROJECTID" ] || [ -z "$REGION" ] || [ -z "$CREDENTIALSFILELOCATION" ] || [ -z "$KEYFILEPATHNAMEANDEXTENSION" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi

  echo -e "\nDeleting Prerequisite Resources..."
  cd 01-terraform || exit

  terraform destroy -auto-approve -var="aws_region=$REGION"
else
  # Create Terraform destroy variable and read file with values
  terraform="terraform destroy -auto-approve "
  file="$1"
  
  while IFS= read line
  do
    terraform="${terraform} -var="$line""
  done <"$file"

  echo -e "\nDeleting Prerequisite Resources..."
  cd 01-terraform || exit
    
  echo $terraform
  eval $terraform
fi
