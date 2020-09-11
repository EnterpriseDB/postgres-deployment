#! /bin/bash

if [ -z "$1" ] 
then
  read -r -e -p "Please provide Project File Name : " PROJECTFILENAME
  read -r -e -p "Please provide OS name and version from: 'CentOS7' 'RHEL7': " OS
  read -r -e -p "Please provide Google Project ID: " PROJECTID
  read -r -e -p "Please provide target GCP Location, examples: 'us-central1','us-east1', 'us-east4', 'us-west1', 'us-west2', 'us-west3' and 'us-west4': " REGION 
  read -r -e -p "Please provide how many GCP VMs to create, example '>=3': " INSTANCE_COUNT
  read -r -e -p "Provide: Absolute path of credentials json file, example: '~/accounts.json': " CREDENTIALSFILELOCATION
  read -r -e -p "Provide: Absolute path of key file, example: '~/.ssh/id_rsa.pub': " KEYFILEPATHNAMEANDEXTENSION
 
  if [ -z "$PROJECTFILENAME" ] || [ -z "$OS" ] || [ -z "$PROJECTID" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_COUNT" ] || [ -z "$CREDENTIALSFILELOCATION" ] || [ -z "$KEYFILEPATHNAMEANDEXTENSION" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi

  echo -e "\nStoring Project File Name Settings ..."
  exec 3<> $PROJECTFILENAME.txt
    echo "os=$OS" >&3
    echo "project_name=$PROJECTID" >&3
    echo "subnetwork_region=$REGION" >&3
    echo "instance_count=$INSTANCE_COUNT" >&3
    echo "credentials=$CREDENTIALSFILELOCATION" >&3
    echo "ssh_key_location=$KEYFILEPATHNAMEANDEXTENSION" >&3
  exec 3>&-   
  
  if [ "$OS" == "CentOS7" ]
  then  
    #OSVERSION="centos-7-v20170816"
    OSVERSION="centos-7-v20200403"
  fi

  if [ "$OS" == "RHEL7" ]
  then
    OSVERSION="rhel-7-v20200403"
  fi

  echo -e "\nCreating Prerequisite Resources..."
  cd 01-terraform || exit
 
  terraform init
  terraform apply -auto-approve -var="os=$OSVERSION" -var="project_name=$PROJECTID" -var="subnetwork_region=$REGION" -var="instance_count=$INSTANCE_COUNT" -var="credentials=$CREDENTIALSFILELOCATION" -var="ssh_key_location=$KEYFILEPATHNAMEANDEXTENSION"
 
  if [ "$?" = "0" ]; then
    # Wait for VMs to be fully available
    echo -e '\nWaiting for VMs to be available...'
    sleep 20s
    echo 'VMs are available!'  
  fi
else
  # Create Terraform destroy variable and read file with values
  terraform="terraform apply -auto-approve "
  if [ -z "$1" ] ; then
    echo 'Entered Project File Name cannot be blank please try again!' 
    exit 0 
  else
    file="$1"
  fi
  while IFS= read line
  do
    if [ "$line" == "os=CentOS7" ] ; then
      #terraform="${terraform} -var="os=centos-7-v20170816"      
      terraform="${terraform} -var="os=centos-7-v20170816""
    else
      if [ "$line" == "os=RHEL7" ] ; then
        terraform="${terraform} -var="os=rhel-7-v20200403""
      else
        terraform="${terraform} -var="$line""
      fi
    fi
  done <"$file"

  echo -e "\nCreating Prerequisite Resources..."
  cd 01-terraform || exit

  terraform init
  echo $terraform 
  eval $terraform
fi
