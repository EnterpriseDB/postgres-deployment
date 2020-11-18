#! /bin/bash
################################################################################
# Title           : pre_install_funcs for installing PG/EPAS on the server
#                 : for deployment scripts
# Author          : Doug Ortiz and Co-authored by Vibhor Kumar
# Date            : Sept 7, 2020
# Version         : 1.0
################################################################################

################################################################################
# quit on any error
set -e
# verify any  undefined shell variables
#set -u

################################################################################
# source common lib
################################################################################
DIRECTORY=$(dirname $0)
if [[ "${DIRECTORY}" = "." ]]
then
   DIRECTORY="${PWD}"
fi
source ${DIRECTORY}/lib/common_funcs.sh

################################################################################
# function: aws_ansible_pg_install
################################################################################
function ansible_pg_install()
{
    local F_OSNAME="$1"
    local F_PG_TYPE="$2"
    local F_PG_VERSION="$3"
    local F_YUM_USERNAME="$4"
    local F_YUM_PASSWORD="$5"
    local F_SSH_KEY="$6"
    local F_PUB_KEY="$7"
    local F_PROJECTNAME="$8"
    local F_EMAILID="$9"
    local F_ROUTE53_ACCESS_KEY="${10}"
    local F_ROUTE53_SECRET="${11}"
    local F_PROJECT_DIR="${12}"

    local F_ANSIBLE_VARS
    local F_ANSIBLE_USER
    local F_NEW_PUB_KEY
    local F_NEW_SSH_KEY
    local F_PUBLIC_KEY
    local F_PRIVATE_KEY

    local F_PROJECT_PUB_KEY="${F_PROJECT_DIR}/${F_PROJECTNAME}_key.pub"
    local F_PROJECT_PEM_KEY="${F_PROJECTNAME}_key.pem"

    F_ANSIBLE_VARS="os=${F_OSNAME} pg_type=${F_PG_TYPE}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} pg_version=${F_PG_VERSION}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} yum_username=${F_YUM_USERNAME}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} yum_password=${F_YUM_PASSWORD}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} pass_dir=${F_PROJECT_DIR}/.edbpass"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} project=${F_PROJECTNAME}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} email_id=${F_EMAILID}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} route53_access_key=${F_ROUTE53_ACCESS_KEY}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} route53_secret=${F_ROUTE53_SECRET}"
    F_ANSIBLE_VARS="${F_ANSIBLE_VARS} public_key=${F_PROJECT_PUB_KEY}"

    local F_LOG_FILE="${F_PROJECT_DIR}/projectdetails.txt"    

    # Check the F_OSNAME and and accordingly set the ansible user
    if [[ "${F_OSNAME}" =~ "CentOS" ]]
    then
        F_ANSIBLE_USER="centos"
        F_NEW_PUB_KEY="centos_${F_PROJECTNAME}_key.pub"
        F_NEW_SSH_KEY="centos_${F_PROJECTNAME}_key.pem"
    elif [[ "${F_OSNAME}" =~ "RHEL" ]]
    then
        F_ANSIBLE_USER="ec2-user"
        F_NEW_PUB_KEY="ec2-user_${F_PROJECTNAME}_key.pub"
        F_NEW_SSH_KEY="ec2-user_${F_PROJECTNAME}_key.pem"
    else
        exit_on_error "Unknown Operating system"
    fi
   
    # Download the ansible collections
    ansible-galaxy collection install edb_devops.edb_postgres \
                --force >> ${PG_INSTALL_LOG} 2>&1
               
    # switch to project directory before executing the ansible
    cd ${F_PROJECT_DIR} || exit 1

    # Check if we have F_PROJECT_PEM_KEY created. If not, create
    # a new one.
    if [[ ! -f ${F_PROJECT_PEM_KEY} ]]
    then
       ssh-keygen -q -t rsa -f ${F_PROJECTNAME}_key -C "" -N ""
       mv ${F_PROJECTNAME}_key ${F_PROJECT_PEM_KEY}
    fi
   
    # Check if we have already copied the users F_PUB_KEY or not.
    # if not then copy with proper name.
    if [[ ! -f ${F_NEW_PUB_KEY} ]]
    then
      cp -f ${F_PUB_KEY} ${F_NEW_PUB_KEY}
      cp -f ${F_SSH_KEY} ${F_NEW_SSH_KEY}
    fi

    # Execute the ansible playbook with all the parameters
    ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' \
                     --user="${F_ANSIBLE_USER}" \
                     --extra-vars="${F_ANSIBLE_VARS}" \
                     --private-key="./${F_NEW_SSH_KEY}" \
                     playbook.yml

    exec 3>&1 1>>"${F_LOG_FILE}" 2>&1
                    
    # Print the POT environment details below after successful execution
    # of the ansible
    echo -e "PEM SERVER:" | tee /dev/fd/3
    echo -e "-----------" | tee /dev/fd/3
    echo -e "  PEM URL:\thttps://${F_PROJECTNAME}pem.edbpov.io:8443/pem"  \
            | tee /dev/fd/3

    if [[ "${F_PG_TYPE}" = "PG" ]]
    then
       echo -e "  Username:\tpostgres" | tee /dev/fd/3
       echo -e "  Password:\t$(cat ${F_PROJECT_DIR}/.edbpass/postgres_pass)" \
         | tee /dev/fd/3
       echo "" | tee /dev/fd/3
    else
       echo -e "  Username:\tenterprisedb" | tee /dev/fd/3
       echo -e "  Password:\t$(cat ${F_PROJECT_DIR}/.edbpass/enterprisedb_pass)" \
         | tee /dev/fd/3
       echo "" | tee /dev/fd/3
    fi
   
    echo -e "EPAS1 - Primary database server" | tee /dev/fd/3
    echo -e "-------------------------------" | tee /dev/fd/3
    F_PUBLIC_IP=$(parse_yaml hosts.yml|grep epas1 \
                  | grep public_ip|cut -d"=" -f2|xargs echo)
    F_PRIVATE_IP=$(parse_yaml hosts.yml|grep epas1 \
                  | grep private_ip|cut -d"=" -f2|xargs echo)
    echo -e "  Login IP address:\t${F_PUBLIC_IP}" | tee /dev/fd/3
    echo -e "  Login user:\t${F_PROJECTNAME}" | tee /dev/fd/3
    echo -e "  Internal IP address:\t${F_PRIVATE_IP}" | tee /dev/fd/3
    echo "" | tee /dev/fd/3
    echo -e "EPAS2 - Streaming Replica 1 (asynchronous)" | tee /dev/fd/3
    echo -e "------------------------------------------" | tee /dev/fd/3
    F_PUBLIC_IP=$(parse_yaml hosts.yml|grep epas2 \
                  | grep public_ip|cut -d"=" -f2|xargs echo)
    F_PRIVATE_IP=$(parse_yaml hosts.yml|grep epas2 \
                  | grep private_ip|cut -d"=" -f2|xargs echo)
    echo -e "  Login IP address:\t${F_PUBLIC_IP}" | tee /dev/fd/3
    echo -e "  Login user:\t${F_PROJECTNAME}" | tee /dev/fd/3
    echo -e "  Internal IP address:\t${F_PRIVATE_IP}" | tee /dev/fd/3
    echo "" | tee /dev/fd/3
    echo -e "EPAS3 - Streaming Replica 2 (asynchronous)" | tee /dev/fd/3
    echo -e "------------------------------------------" | tee /dev/fd/3
    F_PUBLIC_IP=$(parse_yaml hosts.yml|grep epas2 \
                  | grep public_ip|cut -d"=" -f2|xargs echo)
    F_PRIVATE_IP=$(parse_yaml hosts.yml|grep epas2 \
                  | grep private_ip|cut -d"=" -f2|xargs echo)
    echo -e "  Login IP address:\t${F_PUBLIC_IP}" | tee /dev/fd/3
    echo -e "  Login user:\t${F_PROJECTNAME}" | tee /dev/fd/3
    echo -e "  Internal IP address:\t${F_PRIVATE_IP}" | tee /dev/fd/3
    echo "" | tee /dev/fd/3
    echo -e "CLIENT - host to run psql to access the cluster" | tee /dev/fd/3
    echo -e "-----------------------------------------------" | tee /dev/fd/3
    F_PUBLIC_IP=$(parse_yaml hosts.yml|grep pemserver \
                  | grep public_ip|cut -d"=" -f2|xargs echo)
    echo -e "  Login IP address:\t${F_PUBLIC_IP}" | tee /dev/fd/3
    echo -e "  Login user:\t${F_PROJECTNAME}" | tee /dev/fd/3
    echo "" | tee /dev/fd/3

    exec > /dev/tty 2>&1    
}
