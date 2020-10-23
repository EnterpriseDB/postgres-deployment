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
    local F_AMI_ID=""
    local F_IMAGE_NAME=""
    local F_INSTANCE_TYPE="c5.2xlarge"
    local F_PRIV_FILE_KEYPATH="$7"
    local F_PUB_KEYNAMEANDEXTENSION=""
    local F_PRIV_KEYNAMEANDEXTENSION=""
    
    process_log "Building AWS Servers"
    cd ${DIRECTORY}/terraform/aws || exit 1
    process_log "including project names in the variables and tags"
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" tags.tf.template > tags.tf
    sed "s/PROJECT_NAME/${F_PROJECTNAME}/g" variables.tf.template \
                                        > variables.tf 
   
    case $F_OSNAME in
        "CentOS7")
            shift; 
            F_IMAGE_NAME="CentOS Linux 7 x86_64 HVM EBS*"
            export F_IMAGE_NAME
            ;;
        "CentOS8")
            shift; 
            F_IMAGE_NAME="CentOS 8*"
            export F_IMAGE_NAME
            ;;
        "RHEL7")
            shift; 
            F_IMAGE_NAME="RHEL-7.8-x86_64*"
            export F_IMAGE_NAME
            ;;            
        "RHEL8")
            shift; 
            F_IMAGE_NAME="RHEL-8.2-x86_64*"
            export F_IMAGE_NAME
            ;;                       
    esac    

    process_log "Checking availability of Instance Type in target region"
    instancetypeExists=$(aws ec2 describe-instance-type-offerings --location-type availability-zone  --filters Name=instance-type,Values=${F_INSTANCE_TYPE} --region ${REGION} --output text)
    if [ ! -z "$instancetypeExists" ]
    then
        process_log "Instance Type: '${F_INSTANCE_TYPE}' is available in region: '${REGION}'"
    else
        exit_on_error "Instance Type: '${F_INSTANCE_TYPE}' is not available in region: '${REGION}'"
    fi
       
    process_log "Checking availability of Instance Image in target region"
    F_AMI_ID=$(aws ec2 describe-images --filters Name=name,Values="${F_IMAGE_NAME}" --query 'sort_by(Images, &Name)[-1].ImageId' --region ${REGION} --output text)
    
    if [ ! -z "$F_AMI_ID" ]
    then
        process_log "Instance Image: '${F_AMI_ID}' is available in region: '${REGION}'"
    else
        exit_on_error "Instance Image: '${F_AMI_ID}' is not available in region: '${REGION}'"
    fi

    F_PUB_KEYNAMEANDEXTENSION=$(get_string_after_lastslash "${F_KEYPATH}")
    F_PRIV_KEYNAMEANDEXTENSION=$(get_string_after_lastslash "${F_PRIV_FILE_KEYPATH}")
    F_NEW_PUB_KEYNAME=$(join_strings_with_underscore "${F_PROJECTNAME}" "${F_PUB_KEYNAMEANDEXTENSION}")
    F_NEW_PRIV_KEYNAME=$(join_strings_with_underscore "${F_PROJECTNAME}" "${F_PRIV_KEYNAMEANDEXTENSION}")    
    cp -f "${F_KEYPATH}" "${F_NEW_PUB_KEYNAME}"
    cp -f "${F_PRIV_FILE_KEYPATH}" "${F_NEW_PRIV_KEYNAME}"

    if output=$(terraform workspace show | grep "${F_PROJECTNAME}")  &&  [ ! -z "$output" ]
    then
        terraform workspace select "${F_PROJECTNAME}"
    else
        terraform workspace new "${F_PROJECTNAME}"
    fi
        
    terraform init
    
    terraform apply -auto-approve \
        -var="os=${F_OSNAME}" \
        -var="ami_id=${F_AMI_ID}" \
        -var="aws_region=${REGION}" \
        -var="instance_count=${F_INSTANCES}" \
        -var="ssh_key_path=./${F_NEW_PUB_KEYNAME}" \
        -var="cluster_name=$F_PROJECTNAME" \
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
    
    cp -f pem-inventory.yml hosts.yml
        
    mv -f ${DIRECTORY}/terraform/aws/${F_NEW_PUB_KEYNAME} ${PROJECTS_DIRECTORY}/aws/${F_PROJECTNAME}/${F_NEW_PUB_KEYNAME}
    mv -f ${DIRECTORY}/terraform/aws/${F_NEW_PRIV_KEYNAME} ${PROJECTS_DIRECTORY}/aws/${F_PROJECTNAME}/${F_NEW_PRIV_KEYNAME}    
}


################################################################################
# function destroy server
################################################################################
function aws_destroy_server()
{
    local F_REGION="$1"
    local F_PROJECTNAME="$2"

    process_log "Removing AWS Servers"
    cd ${DIRECTORY}/terraform/aws || exit 1

    terraform workspace select "${F_PROJECTNAME}"
        
    terraform destroy -auto-approve \
        -var="aws_region=${REGION}"

    terraform workspace select default
    terraform workspace delete "${F_PROJECTNAME}"
    
    rm -Rf ${PROJECTS_DIRECTORY}/aws/${F_PROJECTNAME}
}

