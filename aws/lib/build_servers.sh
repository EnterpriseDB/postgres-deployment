#! /bin/bash
################################################################################
# Title           : terraform and ansible script to capture the users argument and
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
# source common_fucs
################################################################################
DIRECTORY=$(dirname $0)
source ${DIRECTORY}/lib/common_funcs.sh

################################################################################
# function build server
################################################################################
function aws_build_server()
{
    local F_OSNAME="$1"
    local F_REGION="$2"
    local F_INSTANCES="$3"
    local F_KEYPAIR="$4"
    local F_KEYPATH="$5"
    local F_PEMINSTANCE="$6"
    local F_PROJECTNAME="$7"

    process_log "Building AWS Servers"
    cd ${DIRECTORY}/01-terraform || exit 1
    process_log "including project names in the variables and tags"
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" tags.tf.template > tags.tf
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" variables.tf.template \
                                        > variables.tf 
    terraform init
    terraform apply -auto-approve \
        -var="os=${F_OSNAME}" \
        -var="aws_region=${REGION}" \
        -var="instance_count=${F_INSTANCES}" \
        -var="ssh_keypair=${F_KEYPAIR}" \
        -var="ssh_key_path=${F_KEYPATH}" \
        -var="pem_instance_count=${F_PEMINSTANCE}"

    if [[ $? -eq 0 ]]
    then
        process_log "Waiting for Instances to be available"
        aws ec2 wait instance-status-ok --region "${F_REGION}"
        process_log "instances are ready"
    else
        exit_on_error "Failed to build the servers."
    fi
    sed -i "/^ */d" inventory.yml
    sed -i "/^ *$/d" pem-inventory.yml
    
    if [[ ${F_PEMINSTANCE} -gt 0 ]]
    then
        cp -f pem-inventory.yml hosts.yml
    else
        cp -f inventory.yml hosts.yml
    fi
}

################################################################################
# function destroy server
################################################################################
function aws_destroy_server()
{
    local F_REGION="$1"

    process_log "Removing AWS Servers"
    cd ${DIRECTORY}/01-terraform || exit 1
    
    terraform destroy -auto-approve \
        -var="aws_region=${REGION}"
}
