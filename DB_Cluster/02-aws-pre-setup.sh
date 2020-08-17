read -e -p "Would you like to: Setup AWS Prerequisites? Enter Yes or No:  " response
if [ $response == "Yes" ] || [ $response == "yes" ] || [ $response == "YES" ] 
then
  read -e -p "Please provide OS name from 'CentOS7' or 'RHEL7': " osname
  read -e -p "Please provide target AWS Region: " region
  read -e -p "Please provide how many AWS EC2 Instances to create, example '>=3': " instance_count
  read -e -p "Provide: Name of pem file with no extension, example: 'mypemfile' : " pemfilename
  read -e -p "Provide: Absolute path of pem file, example: '~/mypemfile.pem': " pemfilepathnameandextension

  echo "Creating Prerequisite Resources..."
  cd 01-prereqs-terraform-aws
  terraform init
  terraform apply -auto-approve -var="os=$osname" -var="aws_region=$region" -var="instance_count=$instance_count" -var="ssh_keypair=$pemfilename" -var="ssh_key_path=$pemfilepathnameandextension"

  if [ -z "$osname" ] || [ -z "$region" ] || [ -z "$instance_count" ] || [ -z "$pemfilename" ] || [ -z "$pemfilepathnameandextension" ]
  then 
    echo 'Entered values cannot be blank please try again!' 
    exit 0 
  fi
    
  if [ $? -eq 0 ]; then
    cd ..
  fi
  
  # Copy the recently created Ansible Inventory File to Ansible Galaxy Collection
  cp ./01-prereqs-terraform-aws/inventory.yml ~/.ansible/collections/ansible_collections/edb_devops/edb_postgres/playbook-examples/hosts.yml
  
  # Copy the 'add-host.sh' script file for local execution  
  cp ./01-prereqs-terraform-aws/add_host.sh .
fi
