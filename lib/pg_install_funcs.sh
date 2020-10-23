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
    local F_PUB_FILE_KEYPATH="$7"
    local F_PROJECTNAME="$8"
    local PEM_INSTANCE_COUNT="$9"
    local PEM_EXISTS=0
    local PRIMARY_EXISTS=0
    local STANDBY_EXISTS=0

    local ANSIBLE_EXTRA_VARS

    ANSIBLE_EXTRA_VARS="os=${OSNAME} pg_type=${PG_TYPE}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} pg_version=${PG_VERSION}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} yum_username=${EDB_YUM_USERNAME}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} yum_password=${EDB_YUM_PASSWORD}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} pass_dir=${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/.edbpass"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} project=${PROJECT_NAME}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} email_id=${EmailId}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} route53_access_key=${ROUTE53_ACCESS_KEY}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} route53_secret=${ROUTE53_SECRET}"
    ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} public_key=${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}_user_rsa.pub"

    if [[ "${OSNAME}" =~ "CentOS" ]]
    then
        ANSIBLE_USER="centos"
    elif [[ "${OSNAME}" =~ "RHEL" ]]
    then
        ANSIBLE_USER="ec2-user"
    else
        exit_on_error "Unknown Operating system"
    fi
    
    ansible-galaxy collection install edb_devops.edb_postgres \
                --force >> ${PG_INSTALL_LOG} 2>&1
                
    cd ${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME} || exit 1
    ssh-keygen -q -t rsa -f ${PROJECT_NAME}_user_rsa -C "" -N ""

    F_PUB_KEYNAMEANDEXTENSION=$(get_string_after_lastslash "${F_PUB_FILE_KEYPATH}")
    F_PRIV_KEYNAMEANDEXTENSION=$(get_string_after_lastslash "${SSH_KEY}")
    F_NEW_PUB_KEYNAME=$(join_strings_with_underscore "${F_PROJECTNAME}" "${F_PUB_KEYNAMEANDEXTENSION}")
    F_NEW_PRIV_KEYNAME=$(join_strings_with_underscore "${F_PROJECTNAME}" "${F_PRIV_KEYNAMEANDEXTENSION}")
    cp -f "${F_PUB_FILE_KEYPATH}" "${F_NEW_PUB_KEYNAME}"
    cp -f "${SSH_KEY}" "${F_NEW_PRIV_KEYNAME}"
       
    ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' \
                  --user="${ANSIBLE_USER}" \
                  --extra-vars="${ANSIBLE_EXTRA_VARS}" \
                  --private-key="./${F_NEW_PRIV_KEYNAME}" \
                 playbook.yml
                    
    PEM_EXISTS=$(parse_yaml hosts.yml|grep pemserver|wc -l)
    PRIMARY_EXISTS=$(parse_yaml hosts.yml|grep primary|wc -l)
    STANDBY_EXISTS=$(parse_yaml hosts.yml|grep standby|wc -l)
    
    #if [[ ${PEM_EXISTS} -gt 0 ]]
    if [[ ${PEM_INSTANCE_COUNT} -gt 0 ]]    
    then
        echo -e "PEM SERVER:"
        echo -e "-----------"
        for pemsvr in $(parse_yaml hosts.yml|grep pemserver \
                            |grep public_ip|cut -d"=" -f2|xargs echo)
        do
           echo -e "  PEM URL:\thttps://${PROJECT_NAME}pem.edbpov.io:8443/pem"
           if [[ "${PG_TYPE}" = "PG" ]]
           then
             echo -e "  Username:\tpostgres"
             echo -e "  Password:\t$(cat ${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/.edbpass/postgres_pass)"
             echo ""
           else
             echo -e "  Username:\tenterprisedb"
             echo -e "  Password:\t$(cat ${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/.edbpass/enterprisedb_pass)"
             echo ""
           fi
        done
    fi
   
    if [[ ${PRIMARY_EXISTS} -gt 0 ]]
    then
        echo -e "PRIMARY SERVER"
        echo -e "--------------"
        for srv  in $(parse_yaml hosts.yml|grep epas1 \
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
        for srv  in $(parse_yaml hosts.yml|grep -e epas2 -e epas3 \
                         |grep public_ip|cut -d"=" -f2|xargs echo)
        do
            echo -e "  Username:\t${ANSIBLE_USER}"
            echo -e "  Public Ip:\t${srv}"
            echo ""
        done
    fi
}
