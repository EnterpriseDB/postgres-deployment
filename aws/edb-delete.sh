#! /bin/bash

if [ -z "$1" ] 
then
  read -r -e -p "Please provide target AWS Region, examples: 'us-east1', 'us-west-1'or 'us-west-1':  " REGION
 
  if [ -z "$REGION" ]
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
