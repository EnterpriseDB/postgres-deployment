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
    local F_KEYPATH="$4"
    local F_PEMINSTANCE="$5"
    local F_PROJECTNAME="$6"

    process_log "Building AWS Servers"
    cd ${DIRECTORY}/aws || exit 1
    process_log "including project names in the variables and tags"
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" tags.tf.template > tags.tf
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" variables.tf.template \
                                        > variables.tf 
    terraform init
    terraform apply -auto-approve \
        -var="os=${F_OSNAME}" \
        -var="aws_region=${REGION}" \
        -var="instance_count=${F_INSTANCES}" \
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


function azure_build_server()
{
    #local F_OSNAME="$1"
    #local F_REGION="$2"
    #local F_INSTANCES="$3"
    #local F_KEYPATH="$4"
    #local F_PEMINSTANCE="$5"
    #local F_PROJECTNAME="$6"
    
    local F_PUBLISHER="$1"
    local F_OFFER="$2"
    local F_SKU="$3"
    local F_LOCATION="$4"
    local F_INSTANCE_COUNT="$5"
    local F_SSH_KEY_PATH="$6"
    local F_PROJECTNAME="$7"
    local F_EDB_PREREQ_GROUP=""

    process_log "Building Azure Servers"
    cd ${DIRECTORY}/azure || exit 1
    process_log "including project names in the variables and tags"
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" tags.tf.template > tags.tf
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" variables.tf.template \
                                        > variables.tf 
    terraform init
    #terraform apply -auto-approve \
    #    -var="publisher=${F_PUBLISHER}" \
    #    -var="offer=${F_OFFER}" \
    #    -var="instance_count=${F_INSTANCES}" \
    #    -var="ssh_key_path=${F_KEYPATH}" \
    #    -var="pem_instance_count=${F_PEMINSTANCE}"

    terraform apply -auto-approve \
         -var="publisher=$PUBLISHER" \
         -var="offer=$OFFER" \
         -var="sku=$SKU" \
         -var="azure_location=$LOCATION" \
         -var="instance_count=1" \
         -var="ssh_key_path=$KEYFILEPATHNAMEANDEXTENSION"

    F_EDB_PREREQ_GROUP="$F_PROJECT_NAME"         
    F_EDB_PREREQ_GROUP+="+EDB_PREQ_GROUP"
  
    if [ "$?" = "0" ]; then
      # Wait for VMs to be fully available
      az vm wait --ids $(az vm list -g "$F_EDBPREREQ_GROUP" --query "[].id" -o tsv) --created
    fi

    # Execute with the correct instance count
    #terraform apply -auto-approve \
         #-var="publisher=$PUBLISHER" \
         #-var="offer=$OFFER" \
         #-var="sku=$SKU" \
         #-var="azure_location=$LOCATION" \
         #-var="instance_count=$F_PEM_INSTANCE_COUNT" \
         #-var="ssh_key_path=$KEYFILEPATHNAMEANDEXTENSION"

    if [[ $? -eq 0 ]]
    then
        process_log "Waiting for Instances to be available"
      az vm wait --ids $(az vm list -g "$F_EDBPREREQ_GROUP" --query "[].id" -o tsv) --created
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
    cd ${DIRECTORY}/aws || exit 1
    
    terraform destroy -auto-approve \
        -var="aws_region=${REGION}"
}

function azure_destroy_server()
{
    local F_REGION="$1"

    process_log "Removing Azure Servers"
    cd ${DIRECTORY}/azure || exit 1
    
    terraform destroy -auto-approve \
        -var="aws_region=${REGION}"
}
