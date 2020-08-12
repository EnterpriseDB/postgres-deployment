function input {

read -e -p "Please provide OS name from 'CentOS7' or 'RHEL7': " osname
read -e -p "Please provide Postgresql DB version. Options are 10, 11 or 12: " pgversion
read -e -p "Provide absolute path of pem file: " pemfilepath

if [ "$osname" == CentOS7 ] && [ "$pgversion" == 10 ];then 
ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == CentOS7 ] && [ "$pgversion" == 11 ];then 
ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == CentOS7 ] && [ "$pgversion" == 12 ];then
ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == "10" ];then 
ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == "11" ];then 
ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == "12" ];then
ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

else
echo "You have exeeded maximum attempt to run script. Please try again"
exit 0
fi
}

read -e -p "Would you like to perform step-1. Enter Yes or No:  " response
if [ $response == "Yes" ] || [ $response == "yes" ] || [ $response == "YES" ]
then
echo "Creating prerequesite resource"
cd 01-prereqs
terraform init
terraform apply -auto-approve
if [ $? -eq 0 ]; then
    cd ..
fi
fi

read -e -p "Would you like to perform Step 2. Enter Yes or No: " response

if [ "$response" == "Yes" ] || [ "$response" == "yes" ] || [ "$response" == "YES" ]
then
echo "Creating Instances for DB cluster setup..."
sleep 5
echo "Please fill input file"
vi 02-cluster/edb_cluster_input.tf
cd 02-cluster
terraform init
terraform apply -auto-approve 
if [ $? -eq 0 ]; then
    cd ..
fi
fi

read -e -p "Would you like to perform Step 3. Enter Yes or No: " response

if [ "$response" == "Yes" ] || [ "$response" == "yes" ] || [ "$response" == "YES" ]
then
echo "Setting up Postgres on Instances"
sleep 3
echo "Enter Server IP details in the file"
sleep 2
vi 03-install/hosts.yml
read -e -p "Please provide OS name from 'CentOS7' or 'RHEL7': " osname
read -e -p "Please provide Postgresql DB version. Options are 10, 11 or 12: " pgversion
read -e -p "Provide absolute path of pem file: " pemfilepath
cd 03-install

if [ "$osname" == CentOS7 ] && [ "$pgversion" == 10 ];then  
ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi
elif [ "$osname" == CentOS7 ] && [ "$pgversion" == 11 ];then
ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi
elif [ "$osname" == CentOS7 ] &&  [ "$pgversion" == "12" ];then
ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == 10 ];then
ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == 11 ];then
ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == 12 ];then
ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi


else
echo "Something went wrong, please try again"
input;
fi
fi


read -e -p "Would you like to perform step4. Enter Yes or No: " response

if [ "$response" == "Yes" ] || [ "$response" == "yes" ] || [ "$response" == "YES" ]
then
echo "Setting up replication between 3 DB servers"
sleep 3
echo "Enter Server IP details and other DB parameters in the file"
sleep 2
vi 04-replication/hosts.yml
read -e -p "Please provide OS name from CentOS7 Debian10 Ubuntu18 RHEL7: " osname
read -e -p "Please provide postgresql DB version. Options are 10, 11 or 12: " pgversion
read -e -p "Provide absolute path of pem file: " pemfilepath
cd 04-replication

if [ "$osname" == CentOS7 ] && [ "$pgversion" == 10 ];then  
sudo ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi
elif [ "$osname" == CentOS7 ] && [ "$pgversion" == 11 ];then
sudo ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi
elif [ "$osname" == CentOS7 ] &&  [ "$pgversion" == "12" ];then
sudo ansible-playbook -u centos --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == 10 ];then
sudo ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == 11 ];then
sudo ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

elif [ "$osname" == "RHEL7" ] && [ "$pgversion" == 12 ];then
sudo ansible-playbook -u ec2-user --private-key "$pemfilepath" playbook.yml --extra-vars="OS=$osname PG_VERSION=$pgversion"
if [ $? -eq 0 ]; then
    cd ..
fi

else
echo "Something went wrong, please try again"
input;
fi

fi
