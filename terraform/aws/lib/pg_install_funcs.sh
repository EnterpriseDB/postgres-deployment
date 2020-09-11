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
source ${DIRECTORY}/lib/common_funcs.sh

################################################################################
# function: ansible_pg_install
################################################################################
function ansible_pg_install()
{
    local OSNAME="$1"
    local PG_TYPE="$2"
    local PG_VERSION="$3"
    local EDB_YUM_USERNAME="$4"
    local EDB_YUM_PASSWORD="$5"
    local SSH_KEY="$6"
    local PEM_EXISTS=0
    local PRIMARY_EXISTS=0
    local STANDBY_EXISTS=0

    local ANSIBLE_EXTRA_VARS

    ANSIBLE_EXTRA_VARS="OS=${OSNAME} PG_TYPE=${PG_TYPE}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} PG_VERSION=${PG_VERSION}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_USERNAME=${EDB_YUM_USERNAME}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} EDB_YUM_PASSWORD=${EDB_YUM_PASSWORD}"


    if [[ "${OSNAME}" = "CentOS7" ]]
    then
        ANSIBLE_USER="centos"
    elif [[ "${OSNAME}" = "RHEL7" ]]
    then
        ANSIBLE_USER="ec2-user"
    else
        exit_on_error "Unknown Operating system"
    fi
    
    ansible-galaxy collection install edb_devops.edb_postgres \
                --force >> ${PG_INSTALL_LOG} 2>&1
    cd ${DIRECTORY}/playbook || exit 1
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
