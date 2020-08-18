read -e -p "Would you like to: Setup Postgres? Enter Yes or No: " response
if [ "$response" == "Yes" ] || [ "$response" == "yes" ] || [ "$response" == "YES" ] 
then
  echo "Adding AWS Infrastructure Keys to local Known Hosts File..."
  ./add_host.sh
  clear

  echo "Downloading Ansible Collection 'edb_devops.edb_postgres' ..."
  #ansible-galaxy collection install edb_devops.edb_postgres --force

  echo "Update Public IP, Private IP and other details in the file..."
  read -e -p "Please provide OS name from 'CentOS7' or 'RHEL7': " osname
  read -e -p "Please provide Postgresql DB version. Options are 10, 11 or 12: " pgversion
  read -e -p "Provide absolute path of pem file: " pemfilepath
  read -e -p "Provide EDB Yum Username: " yumuser
  read -e -p "Provide EDB Yum Password: " yumpass

  if [ -z "$osname" ] || [ -z "$pgversion" ] || [ -z "$pemfilepath" ] || [ -z "$yumuser" ] || [ -z "$yumpass" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi

  if [ "$osname" == CentOS7 ]
  then 
    ansible-playbook -u centos --private-key "$pemfilepath" ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/C07_EPAS12_EFM_install.yml --extra-vars="OS=$osname PG_VERSION=$pgversion EDB_YUM_USERNAME=$yumuser EDB_YUM_PASSWORD=$yumpass"
  fi

  if [ "$osname" == RHEL7 ]
  then 
    ansible-playbook -u ec2-user--private-key "$pemfilepath" ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/RH07_EPAS12_EFM_install.yml --extra-vars="OS=$osname PG_VERSION=$pgversion EDB_YUM_USERNAME=$yumuser EDB_YUM_PASSWORD=$yumpass"
  fi
fi
