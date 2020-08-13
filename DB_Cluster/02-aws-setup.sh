read -e -p "Would you like to perform Step 1 - Setup AWS Prerequisites? Enter Yes or No:  " response
if [ $response == "Yes" ] || [ $response == "yes" ] || [ $response == "YES" ] 
then
  echo "Please review the variables and set accordingly..."
  gedit 01-prereqs-terraform-aws/variables.tf & pid=$!
  wait $pid

  echo "Creating Prerequisite Resources..."
  cd 01-prereqs-terraform-aws
  terraform init
  terraform apply -auto-approve
  if [ $? -eq 0 ]; then
    cd ..
  fi
fi

read -e -p "Would you like to perform Step 2 - Setup Postgres? Enter Yes or No: " response
if [ "$response" == "Yes" ] || [ "$response" == "yes" ] || [ "$response" == "YES" ] 
then
  echo "Downloading Ansible Collection 'edb_devops.edb_postgres' ..."
  #ansible-galaxy collection install edb_devops.edb_postgres --force
  echo "Update Public IP, Private IP and other details in the file..."
  cp ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/hosts-no-pem.yml ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/hosts.yml

  gedit ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/hosts.yml
  read -e -p "Please provide OS name from 'CentOS7' or 'RHEL7': " osname
  read -e -p "Please provide Postgresql DB version. Options are 10, 11 or 12: " pgversion
  read -e -p "Provide absolute path of pem file: " pemfilepath

  if [ -z "$osname" ] || [ -z "$pgversion" ] || [ -z "$pemfilepath" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi

  if [ "$osname" == CentOS7 ]
  then 
    gedit ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/C07_EPAS12_EFM_install.yml
    ansible-playbook -u centos --private-key "$pemfilepath" ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/C07_EPAS12_EFM_install.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
  fi

  if [ "$osname" == RHEL7 ]
  then 
    gedit ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/RH07_EPAS12_EFM_install.yml
    ansible-playbook -u ec2-user--private-key "$pemfilepath" ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/RH07_EPAS12_EFM_install.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
  fi
fi
