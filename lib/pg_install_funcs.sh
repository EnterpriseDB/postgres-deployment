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
function aws_ansible_pg_install()
{
    local OSNAME="$1"
    local PG_TYPE="$2"
    local PG_VERSION="$3"
    local EDB_YUM_USERNAME="$4"
    local EDB_YUM_PASSWORD="$5"
    local SSH_KEY="$6"
    local PEM_INSTANCE_COUNT="$7"
    local PEM_EXISTS=0
    local PRIMARY_EXISTS=0
    local STANDBY_EXISTS=0

    local ANSIBLE_EXTRA_VARS

    ANSIBLE_EXTRA_VARS="OS=${OSNAME} PG_TYPE=${PG_TYPE}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} PG_VERSION=${PG_VERSION}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_USERNAME=${EDB_YUM_USERNAME}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_PASSWORD=${EDB_YUM_PASSWORD}"

    if [[ "${OSNAME}" =~ "CentOS" ]]
    then
        ANSIBLE_USER="centos"
    elif [[ "${OSNAME}" =~ "RHEL" ]]
    then
        ANSIBLE_USER="ec2-user"
    else
        exit_on_error "Unknown Operating system"
    fi
    
    #ansible-galaxy collection install edb_devops.edb_postgres \
    #            --force >> ${PG_INSTALL_LOG} 2>&1
                
    cd ${DIRECTORY}/playbook || exit 1

    if [[ ${PEM_INSTANCE_COUNT} -gt 0 ]]
    then
        cp -f ${DIRECTORY}/terraform/aws/pem-inventory.yml hosts.yml
    else
        cp -f ${DIRECTORY}/terraform/aws/inventory.yml hosts.yml
    fi
        
    ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' \
                     --user="${ANSIBLE_USER}" \
                     --extra-vars="${ANSIBLE_EXTRA_VARS}" \
                     --private-key="${SSH_KEY}" \
                    playbook.yml
                    
    PEM_EXISTS=$(parse_yaml hosts.yml|grep pemserver|wc -l)
    PRIMARY_EXISTS=$(parse_yaml hosts.yml|grep primary|wc -l)
    STANDBY_EXISTS=$(parse_yaml hosts.yml|grep standby|wc -l)
    
    if [[ ${PEM_EXISTS} -gt 0 ]]
    then
        echo -e "PEM SERVER:"
        echo -e "-----------"
        for pemsvr in $(parse_yaml hosts.yml|grep pemserver \
                            |grep public_ip|cut -d"=" -f2|xargs echo)
        do
           echo -e "  PEM URL:\thttps://${pemsvr}:8443/pem"
           if [[ "${PG_TYPE}" = "PG" ]]
           then
             echo -e "  Username:\tpostgres"
             echo -e "  Password:\t$(cat ~/.edb/postgres_pass)"
             echo ""
           else
             echo -e "  Username:\tenterprisedb"
             echo -e "  Password:\t$(cat ~/.edb/enterprisedb_pass)"
             echo ""
           fi
        done
    fi
   
    if [[ ${PRIMARY_EXISTS} -gt 0 ]]
    then
        echo -e "PRIMARY SERVER"
        echo -e "--------------"
        for srv  in $(parse_yaml hosts.yml|grep primary \
                         |grep public_ip|cut -d"=" -f2|xargs echo)
        do
            echo -e "  Username:\t${ANSIBLE_USER}"
            echo -e "  Public Ip:\t${srv}"
            echo ""
        done
    fi
    if [[ ${STANDBY_EXISTS} -gt 0 ]]
    then
        echo -e "STANDBY SERVERS"
        echo -e "--------------"
        for srv  in $(parse_yaml hosts.yml|grep standby \
                         |grep public_ip|cut -d"=" -f2|xargs echo)
        do
            echo -e "  Username:\t${ANSIBLE_USER}"
            echo -e "  Public Ip:\t${srv}"
            echo ""
        done
    fi
}

################################################################################
# function: azure_ansible_pg_install
################################################################################
function azure_ansible_pg_install()
{
    local OSNAME=""
    local PG_TYPE="$1"
    local PG_VERSION="$2"
    local EDB_YUM_USERNAME="$3"
    local EDB_YUM_PASSWORD="$4"
    local SSH_KEY="$5"
    local PEM_INSTANCE_COUNT="$6"
    local PEM_EXISTS=0
    local PRIMARY_EXISTS=0
    local STANDBY_EXISTS=0

    local ANSIBLE_EXTRA_VARS

    cd ${DIRECTORY}/terraform/azure || exit 1
    
    while IFS=, read -r os_name_and_version
    do
      [[ "$os_name_and_version" != "os_name_and_version" ]] && OS_NAME_AND_VERSION=$os_name_and_version
    done < os.csv

    OS="$(echo -e "$OS_NAME_AND_VERSION" | tr -d '[:space:]')"

    if [[ "${OS}" =~ "Cent" ]]        
    then
        ANSIBLE_USER="centos"
        OSNAME="CentOS7"
    elif [[ "${OS}" =~ "RHEL" ]]
    then
        ANSIBLE_USER="ec2-user"
        OSNAME="RHEL7"        
    else
        exit_on_error "Unknown Operating system"
    fi

    cd ${DIRECTORY} || exit 1
        
    ANSIBLE_EXTRA_VARS="OS=${OSNAME} PG_TYPE=${PG_TYPE}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} PG_VERSION=${PG_VERSION}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_USERNAME=${EDB_YUM_USERNAME}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_PASSWORD=${EDB_YUM_PASSWORD}"
  
    ansible-galaxy collection install edb_devops.edb_postgres \
                --force >> ${PG_INSTALL_LOG} 2>&1
                
    cd ${DIRECTORY}/playbook || exit 1
    
    if [[ ${PEM_INSTANCE_COUNT} -gt 0 ]]
    then
        cp -f ${DIRECTORY}/terraform/azure/pem-inventory.yml hosts.yml
    else
        cp -f ${DIRECTORY}/terraform/azure/inventory.yml hosts.yml
    fi
        
    ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' \
                     --user="${ANSIBLE_USER}" \
                     --extra-vars="${ANSIBLE_EXTRA_VARS}" \
                     --private-key="${SSH_KEY}" \
                    playbook.yml
                    
    PEM_EXISTS=$(parse_yaml hosts.yml|grep pemserver|wc -l)
    PRIMARY_EXISTS=$(parse_yaml hosts.yml|grep primary|wc -l)
    STANDBY_EXISTS=$(parse_yaml hosts.yml|grep standby|wc -l)
    
    if [[ ${PEM_EXISTS} -gt 0 ]]
    then
        echo -e "PEM SERVER:"
        echo -e "-----------"
        for pemsvr in $(parse_yaml hosts.yml|grep pemserver \
                            |grep public_ip|cut -d"=" -f2|xargs echo)
        do
           echo -e "  PEM URL:\thttps://${pemsvr}:8443/pem"
           if [[ "${PG_TYPE}" = "PG" ]]
           then
             echo -e "  Username:\tpostgres"
             echo -e "  Password:\t$(cat ~/.edb/postgres_pass)"
             echo ""
           else
             echo -e "  Username:\tenterprisedb"
             echo -e "  Password:\t$(cat ~/.edb/enterprisedb_pass)"
             echo ""
           fi
        done
    fi
   
    if [[ ${PRIMARY_EXISTS} -gt 0 ]]
    then
        echo -e "PRIMARY SERVER"
        echo -e "--------------"
        for srv  in $(parse_yaml hosts.yml|grep primary \
                         |grep public_ip|cut -d"=" -f2|xargs echo)
        do
            echo -e "  Username:\t${ANSIBLE_USER}"
            echo -e "  Public Ip:\t${srv}"
            echo ""
        done
    fi
    if [[ ${STANDBY_EXISTS} -gt 0 ]]
    then
        echo -e "STANDBY SERVERS"
        echo -e "--------------"
        for srv  in $(parse_yaml hosts.yml|grep standby \
                         |grep public_ip|cut -d"=" -f2|xargs echo)
        do
            echo -e "  Username:\t${ANSIBLE_USER}"
            echo -e "  Public Ip:\t${srv}"
            echo ""
        done
    fi
}

################################################################################
# function: gcloud_ansible_pg_install
################################################################################
function gcloud_ansible_pg_install()
{
    local OSNAME=""
    local PG_TYPE="$1"
    local PG_VERSION="$2"
    local EDB_YUM_USERNAME="$3"
    local EDB_YUM_PASSWORD="$4"
    local SSH_KEY="$5"
    local PEM_INSTANCE_COUNT="$6"
    local PEM_EXISTS=0
    local PRIMARY_EXISTS=0
    local STANDBY_EXISTS=0

    local ANSIBLE_EXTRA_VARS

    cd ${DIRECTORY}/terraform/gcloud || exit 1
    
    while IFS=, read -r os_name_and_version
    do
      [[ "$os_name_and_version" != "os_name_and_version" ]] && OS_NAME_AND_VERSION=$os_name_and_version
    done < os.csv

    OS="$(echo -e "$OS_NAME_AND_VERSION" | tr -d '[:space:]')"

    if [[ "${OS}" =~ "centos-7" ]]        
    then
        ANSIBLE_USER="centos"
        OSNAME="CentOS7"
    elif [[ "${OS}" =~ "rhel-7" ]]
    then
        ANSIBLE_USER="ec2-user"
        OSNAME="RHEL7"        
    else
        exit_on_error "Unknown Operating system"
    fi

    cd ${DIRECTORY} || exit 1
        
    ANSIBLE_EXTRA_VARS="OS=${OSNAME} PG_TYPE=${PG_TYPE}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} PG_VERSION=${PG_VERSION}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_USERNAME=${EDB_YUM_USERNAME}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_PASSWORD=${EDB_YUM_PASSWORD}"
  
    ansible-galaxy collection install edb_devops.edb_postgres \
                --force >> ${PG_INSTALL_LOG} 2>&1
                
    cd ${DIRECTORY}/playbook || exit 1
    
    if [[ ${PEM_INSTANCE_COUNT} -gt 0 ]]
    then
        cp -f ${DIRECTORY}/terraform/gcloud/pem-inventory.yml hosts.yml
    else
        cp -f ${DIRECTORY}/terraform/gcloud/inventory.yml hosts.yml
    fi
        
    ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' \
                     --user="${ANSIBLE_USER}" \
                     --extra-vars="${ANSIBLE_EXTRA_VARS}" \
                     --private-key="${SSH_KEY}" \
                    playbook.yml
                    
    PEM_EXISTS=$(parse_yaml hosts.yml|grep pemserver|wc -l)
    PRIMARY_EXISTS=$(parse_yaml hosts.yml|grep primary|wc -l)
    STANDBY_EXISTS=$(parse_yaml hosts.yml|grep standby|wc -l)
    
    if [[ ${PEM_EXISTS} -gt 0 ]]
    then
        echo -e "PEM SERVER:"
        echo -e "-----------"
        for pemsvr in $(parse_yaml hosts.yml|grep pemserver \
                            |grep public_ip|cut -d"=" -f2|xargs echo)
        do
           echo -e "  PEM URL:\thttps://${pemsvr}:8443/pem"
           if [[ "${PG_TYPE}" = "PG" ]]
           then
             echo -e "  Username:\tpostgres"
             echo -e "  Password:\t$(cat ~/.edb/postgres_pass)"
             echo ""
           else
             echo -e "  Username:\tenterprisedb"
             echo -e "  Password:\t$(cat ~/.edb/enterprisedb_pass)"
             echo ""
           fi
        done
    fi
   
    if [[ ${PRIMARY_EXISTS} -gt 0 ]]
    then
        echo -e "PRIMARY SERVER"
        echo -e "--------------"
        for srv  in $(parse_yaml hosts.yml|grep primary \
                         |grep public_ip|cut -d"=" -f2|xargs echo)
        do
            echo -e "  Username:\t${ANSIBLE_USER}"
            echo -e "  Public Ip:\t${srv}"
            echo ""
        done
    fi
    if [[ ${STANDBY_EXISTS} -gt 0 ]]
    then
        echo -e "STANDBY SERVERS"
        echo -e "--------------"
        for srv  in $(parse_yaml hosts.yml|grep standby \
                         |grep public_ip|cut -d"=" -f2|xargs echo)
        do
            echo -e "  Username:\t${ANSIBLE_USER}"
            echo -e "  Public Ip:\t${srv}"
            echo ""
        done
    fi
}
