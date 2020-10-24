#! /bin/bash
################################################################################
# Title           : pre_reqs_funcs.sh making installs the required packages for
#                 : for deployment scripts
# Author          : Doug Ortiz and Co-authored by Vibhor Kumar
# Date            : Sept 7, 2020
# Version         : 1.0
# Notes           : Installs wget, curl terraform and ansible
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
# function: Check the version of the operating system and return package command
################################################################################
function package_command()
{
   local F_OSINFO=$(cat /etc/*release | grep ^NAME)
   local F_OSTYPE
 
   if [[ "${F_OSINFO}" =~ "Red" ]] || [[ "${F_OSINFO}" =~ "CentOS" ]]
   then
       echo "sudo yum -y install"
   elif [[ "${F_OSINFO}" =~ "Ubuntu" ]] || [[ "${F_OSINFO}" =~ "Debian" ]]
   then
       echo "sudo apt -y install"
   else
       exit_on_error "Unknown Operating sytem"
   fi
}


################################################################################
# function: install wget and curl if not exists
################################################################################
function install_wget_curl()
{
    local F_INSTALL_CMD
    local F_WGET_EXISTS
    local F_CURL_EXISTS

    F_INSTALL_CMD=$(package_command)
    F_WGET_EXISTS=$(which wget >/dev/null 2>&1 && echo $? || echo $?)
    F_CURL_EXISTS=$(which curl >/dev/null 2>&1 && echo $? || echo $?)
    
    if [[ ${F_WGET_EXISTS} -ne 0 ]]
    then
        #process_log "Installing wget package"
        #${F_INSTALL_CMD} wget >>${INSTALL_LOG} 2>&1 
        process_log "wget is not installed"
        exit_on_error "wget is not installed"
    fi
    
    if [[ ${F_CURL_EXISTS} -ne 0 ]]
    then
        #process_log "installing curl"
        #${F_INSTALL_CMD} curl >>${INSTALL_LOG} 2>&1
        process_log "curl is not installed"
        exit_on_error "curl is not installed"       
    fi
}


################################################################################
# function: install gawk if not exists
################################################################################
function install_gawk()
{
    local F_INSTALL_CMD
    local F_GAWK_EXISTS

    F_INSTALL_CMD=$(package_command)
    F_GAWK_EXISTS=$(which gawk >/dev/null 2>&1 && echo $? || echo $?)
    
    if [[ ${F_GAWK_EXISTS} -ne 0 ]]
    then
        #process_log "Installing gawk package"
        #${F_INSTALL_CMD} gawk >>${INSTALL_LOG} 2>&1
        process_log "gawk is not installed"
        exit_on_error "gawk is not installed"
    fi
}


################################################################################
# function: install terraform and ansible
################################################################################
function install_terraform()
{
    local F_TERRAFORM_VERSION
    local F_TERRAFORM_ZIP
    local F_RELEASE_URL
    local F_TERRAFORM_EXISTS
    local F_URL="https://api.github.com/repos/hashicorp/terraform/releases/latest"
    local F_BASEURL="https://releases.hashicorp.com/terraform"

    F_TERRAFORM_EXISTS=$(which terraform >/dev/null 2>&1 && echo $? || echo $?)

    if [[ ${F_TERRAFORM_EXISTS} -ne 0 ]]
    then
        process_log "Terraform is not installed"
        exit_on_error "Terraform is not installed"
    fi
}

################################################################################
# function: install ansible 2.9
################################################################################
function install_ansible()
{
    local INSTALL_CMD=$(package_command)
    local DEBIAN_URL
    local ANSIBLE_EXISTS
    local IS_APT
    local IS_YUM

    ANSIBLE_EXISTS=$(which ansible >/dev/null 2>&1 && echo $? || echo $?)
    set +e
    IS_APT=$(echo ${INSTALL_CMD}|grep -q apt)
    IS_YUM=$(echo ${INSTALL_CMD}|grep -q yum)
    set -e
    DEBIAN_URL="http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main"
    
    if [[ ${ANSIBLE_EXISTS} -ne 0 ]] && [[ ${IS_APT} -eq 0 ]]
    then
        set +e
        process_log "Ansible is not installed"
        exit_on_error "Ansible is not installed"        
        set -e
    fi

    if [[ ${ANSIBLE_EXISTS} -ne 0 ]] && [[ ${IS_YUM} -eq 0 ]]
    then
        set +e
        process_log "Ansible is not installed"
        exit_on_error "Ansible is not installed"        
        set -e
    fi
}

################################################################################
# functions: verify aws cli, azure cli or google cloud sdk
################################################################################
function verify_aws()
{
    local AWS_ZIP="awscli-exe-linux-x86_64.zip"
    local AWS_URL="https://awscli.amazonaws.com/${AWS_ZIP}"
    local AWS_EXISTS

    AWS_EXISTS=$(which aws >/dev/null 2>&1 && echo $? || echo $?)
    
    # check if we have credential files
    if [[ ! -f ~/.aws/credentials ]]
    then
        aws configure
    else
        aws sts get-caller-identity >/dev/null
        if [[ $? -ne 0 ]]
        then
            process_log "AWS proper configuration not found"
            aws configure
        fi
    fi
}

