#! /bin/bash

read -r -e -p "Would you like to: Setup Postgres? Enter Yes or No: " RESPONSE
if [ "$RESPONSE" == "Yes" ] || [ "$RESPONSE" == "yes" ] || [ "$RESPONSE" == "YES" ] 
then
  # Copy the 'add-host.sh' script file for local execution  
  cp ./01-terraform/add_host.sh . 

  # Copy the 'os.csv' csv file for local use
  cp ./01-terraform/os.csv . 
  
  echo "Adding AWS Infrastructure Keys to local Known Hosts File..."
  ./add_host.sh
  clear

  echo "Downloading Ansible Collection 'edb_devops.edb_postgres' ..."
  ansible-galaxy collection install edb_devops.edb_postgres --force

  # Copy the recently created Ansible Inventory File to Ansible Galaxy Collection
  cp ./01-terraform/inventory.yml ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/hosts.yml
  
  # Read os.csv file
  while IFS=, read -r os_name_and_version
  do
    [[ "$os_name_and_version" != "os_name_and_version" ]] && OS_NAME_AND_VERSION=$os_name_and_version
  done < os.csv

  OS="$(echo -e "$OS_NAME_AND_VERSION" | tr -d '[:space:]')"
  OSNAME=$OS

  clear
  echo "Update Public IP, Private IP and other details in the file..."
  read -r -e -p "Please provide Postgresql DB Engine. Options are 'PG' or 'EPAS': " PGTYPE
  read -r -e -p "Please provide Postgresql DB Version. Options are 10, 11 or 12: " PGVERSION
  read -r -e -p "Provide: Absolute path of pem file, example: '~/mypemfile.pem':  " PEMFILEPATH
  read -r -e -p "Provide EDB Yum Username: " YUMUSER
  read -r -e -p "Provide EDB Yum Password: " YUMPASSWORD

  if [ -z "$OSNAME" ] || [ -z "$PGTYPE" ] || [ -z "$PGVERSION" ] || [ -z "$PEMFILEPATH" ] || [ -z "$YUMUSER" ] || [ -z "$YUMPASSWORD" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi

  ANSIBLE_USER = 'centos'
  if [ "$OSNAME" == CentOS7 ]
  then 
    ansible-playbook -u centos --private-key "$PEMFILEPATH" ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/C07_EPAS12_EFM_install.yml --extra-vars="OS=$OSNAME PG_TYPE=$PGTYPE PG_VERSION=$PGVERSION EDB_YUM_USERNAME=$YUMUSER EDB_YUM_PASSWORD=$YUMPASSWORD" --ssh-common-args='-o StrictHostKeyChecking=no'
  fi

  if [ "$OSNAME" == RHEL7 ]
  then 
    ansible-playbook -u ec2-user --private-key "$PEMFILEPATH" ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/R07_EPAS12_EFM_install.yml --extra-vars="OS=$OSNAME PG_TYPE=$PGTYPE PG_VERSION=$PGVERSION EDB_YUM_USERNAME=$YUMUSER EDB_YUM_PASSWORD=$YUMPASSWORD" --ssh-common-args='-o StrictHostKeyChecking=no'
  fi
fi
