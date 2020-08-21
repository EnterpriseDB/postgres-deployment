#! /bin/bash

read -r -e -p "Would you like to: Setup Postgres? Enter Yes or No: " RESPONSE
if [ "$RESPONSE" == "Yes" ] || [ "$RESPONSE" == "yes" ] || [ "$RESPONSE" == "YES" ] 
then
  # Copy the 'add-host.sh' script file for local execution  
  cp ./01-prereqs-terraform/add_host.sh . 

  # Copy the 'os.csv' csv file for local use
  cp ./01-prereqs-terraform/os.csv . 
  
  echo "Adding Azure Infrastructure Keys to local Known Hosts File..."
  ./add_host.sh
  clear

  echo "Downloading Ansible Collection 'edb_devops.edb_postgres' ..."
  ansible-galaxy collection install edb_devops.edb_postgres --force

  # Copy the recently created Ansible Inventory File to Ansible Galaxy Collection
  cp ./01-prereqs-terraform/inventory.yml ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/hosts.yml
  
  # Read os.csv file
  while IFS=, read -r os_name_and_version
  do
    [[ "$os_name_and_version" != "os_name_and_version" ]] && OS_NAME_AND_VERSION=$os_name_and_version
  done < os.csv

  OS="$(echo -e "$OS_NAME_AND_VERSION" | tr -d '[:space:]')"
  OSNAME=$OS
  
  # Initialize Admin User
  ANSIBLE_USER="centos"

  clear
  echo "Update Public IP, Private IP and other details in the file..."
  read -r -e -p "Please provide Postgresql DB Engine. Options are 'PG' or 'EPAS': " PGTYPE
  read -r -e -p "Please provide Postgresql DB Version. Options are 10, 11 or 12: " PGVERSION
  read -r -e -p "Provide: Absolute path of private key file, example: '~/.ssh/id_rsa':  " KEYFILEPATH
  read -r -e -p "Provide: VM Admin Username, example: 'centos': " ANSIBLE_USER
  read -r -e -p "Provide EDB Yum Username: " YUMUSER
  read -r -e -p "Provide EDB Yum Password: " YUMPASSWORD

  if [ -z "$OSNAME" ] || [ -z "$PGTYPE" ] || [ -z "$PGVERSION" ] || [ -z "$KEYFILEPATH" ] || [ -z "$YUMUSER" ] || [ -z "$YUMPASSWORD" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi


  PLAYBOOK = "C07_EPAS12_EFM_install.yml"
  
  if [ "$OSNAME" == Centos7.7 ]
  then 
    PLAYBOOK = "C07_EPAS12_EFM_install.yml"
  fi

  if [ "$OSNAME" == RHEL7.8 ]
  then
    PLAYBOOK = "R07_EPAS12_EFM_install.yml"
  fi
  
  # Run playbook
  ansible-playbook -u $ANSIBLE_USER --private-key "$KEYFILEPATH" ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/$PLAYBOOK --extra-vars="OS=CentOS7 PG_TYPE=$PGTYPE PG_VERSION=$PGVERSION EDB_YUM_USERNAME=$YUMUSER EDB_YUM_PASSWORD=$YUMPASSWORD" --ssh-common-args='-o StrictHostKeyChecking=no'
  
fi
