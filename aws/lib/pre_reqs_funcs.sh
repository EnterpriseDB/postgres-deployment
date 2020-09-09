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

   F_OSTYPE="$(echo ${F_OSINFO}|awk '{ match($0,"CentOS",a)}END{print a[0]}')"
   set +e
   [[ -z ${F_OSTYPE} ]] && \
        F_OSTYPE="$(echo ${F_OSINFO}|awk '{ match($0,"Ubuntu",a)}END{print a[0]}')"
   [[ -z ${F_OSTYPE} ]] && \
        F_OSTYPE="$(echo ${F_OSINFO}|awk '{ match($0,"Debian",a)}END{print a[0]}')"
   [[ -z ${F_OSTYPE} ]] && \
        F_OSTYPE="$(echo ${F_OSINFO}|awk '{ match($0,"Red",a)}END{print a[0]}')"
   set -e 
   if [[ "${F_OSTYPE}" = "Red" ]] || [[ "${F_OSTYPE}" = "CentOS" ]]
   then
       echo "yum -y install"
   elif [[ "${F_OSTYPE}" = "Ubuntu" ]] || [[ "${F_OSTYPE}" = "Debian" ]]
   then
       echo "apt -y install"
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
        process_log "Installing wget package"
        ${F_INSTALL_CMD} wget >>${INSTALL_LOG} 2>&1 
    fi
    if [[ ${F_CURL_EXISTS} -ne 0 ]]
    then
        process_log "installing curl"
        ${F_INSTALL_CMD} curl >>${INSTALL_LOG} 2>&1
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
        process_log "Installing terraform"
        F_URL="https://api.github.com/repos/hashicorp/terraform/releases/latest"
        F_TERRAFORM_VERSION="$(curl -s ${F_URL} \
                              | grep tag_name \
                              | cut -d: -f2 \
                              | tr -d \"\,v \
                              | awk '{$1=$1};1')"
        F_TERRAFORM_ZIP="terraform_${F_TERRAFORM_VERSION}_linux_amd64.zip"
        F_RELEASE_URL="${F_BASEURL}/${F_TERRAFORM_VERSION}/${F_TERRAFORM_ZIP}"
        wget ${F_RELEASE_URL} >>${INSTALL_LOG} 2>&1
        unzip ${F_TERRAFORM_ZIP} >>${INSTALL_LOG} 2>&1
        mv terraform /usr/local/bin >>${INSTALL_LOG} 2>&1
        rm -f ${F_TERRAFORM_ZIP}
        terraform --version >>${INSTALL_LOG} 2>&1
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
        process_log "Installing ansible"
        ${INSTALL_CMD} software-properties-common >>${INSTALL_LOG} 2>&1
        apt-add-repository --yes --update ppas:ansible/ansible >>${INSTALL_LOG} 2>&1
        ${INSTALL_CMD} ansible >>${INSTALL_LOG} 2>&1
        apt-key adv  --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 >>${INSTALL_LOG} 2>&1
        apt update >>${INSTALL_LOG} 2>&1
        ${INSTALL_CMD} ansible >>${INSTALL_LOG} 2>&1
        set -e
    fi

    if [[ ${ANSIBLE_EXISTS} -ne 0 ]] && [[ ${IS_YUM} -eq 0 ]]
    then
        set +e
        process_log "Installing ansible"
        ${INSTALL_CMD} epel-release >>${INSTALL_LOG} 2>&1
        subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms \
            >>${INSTALL_LOG} 2>&1
        ${INSTALL_CMD} ansible >>${INSTALL_LOG} 2>&1
        set -e
    fi
    ansible --version >>${INSTALL_LOG} 2>&1
}

################################################################################
# function: install aws cli
################################################################################
function install_aws()
{
    local AWS_ZIP="awscli-exe-linux-x86_64.zip"
    local AWS_URL="https://awscli.amazonaws.com/${AWS_ZIP}"
    local AWS_EXISTS

    AWS_EXISTS=$(which aws >/dev/null 2>&1 && echo $? || echo $?)

    if [[ ${AWS_EXISTS} -ne 0 ]]
    then
        wget ${AWS_URL} >>${INSTALL_LOG} 2>&1
        unzip ${AWS_ZIP} >>${INSTALL_LOG} 2>&1
        ./aws/install --update >>${INSTALL_LOG} 2>&1
    fi
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
