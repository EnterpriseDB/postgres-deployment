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
set -u

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
    local F_PUB_KEY="$4"
    local F_PEMINSTANCE="$5"
    local F_PROJECTNAME="$6"
    local F_SSH_KEY="$7"
    local F_PROJECT_DIR="$8"

    local F_AMI_ID=""
    local F_IMAGE_NAME=""

    local F_INSTANCE_EXISTS=""
    local F_INSTANCE_TYPE="c5.2xlarge"
    local F_NEW_PUB_KEY="${F_PROJECTNAME}_key.pub"
    local F_NEW_SSH_KEY="${F_PROJECTNAME}_key.pem"
   
    local F_CHECK=""

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
            F_NEW_PUB_KEY="centos_key.pub"
            F_NEW_SSH_KEY="centos_key.pem"
            export F_IMAGE_NAME
            ;;
        "CentOS8")
            shift; 
            F_IMAGE_NAME="CentOS 8*"
            F_NEW_PUB_KEY="centos_key.pub"
            F_NEW_SSH_KEY="centos_key.pem"
            export F_IMAGE_NAME
            ;;
        "RHEL7")
            shift; 
            F_IMAGE_NAME="RHEL-7.8-x86_64*"
            F_NEW_PUB_KEY="ec2-user_key.pub"
            F_NEW_SSH_KEY="ec2-user_key.pem"
            export F_IMAGE_NAME
            ;;            
        "RHEL8")
            shift; 
            F_IMAGE_NAME="RHEL-8.2-x86_64*"
            F_NEW_PUB_KEY="ec2-user_key.pub"
            F_NEW_SSH_KEY="ec2-user_key.pem"
            export F_IMAGE_NAME
            ;;                       
    esac    

    process_log "Checking availability of Instance Type in target region"
    F_INSTANCE_EXISTS=$(aws ec2 describe-instance-type-offerings \
                             --location-type availability-zone  \
                             --filters Name=instance-type,Values=${F_INSTANCE_TYPE} \
                             --region ${F_REGION} \
                             --output text)
    if [ ! -z "${F_INSTANCE_EXISTS}" ]
    then
        process_log "Instance Type: '${F_INSTANCE_TYPE}' is available in region: '${REGION}'"
    else
        exit_on_error "Instance Type: '${F_INSTANCE_TYPE}' is not available in region: '${REGION}'"
    fi
       
    process_log "Checking availability of Instance Image in target region"
    F_AMI_ID=$(aws ec2 describe-images \
                  --filters Name=name,Values="${F_IMAGE_NAME}" \
                  --query 'sort_by(Images, &Name)[-1].ImageId'\
                  --region ${REGION} --output text)
    
    if [[ ! -z "${F_AMI_ID}" ]]
    then
        process_log "Instance Image: '${F_AMI_ID}' is available in region: '${REGION}'"
    else
        exit_on_error "Instance Image: '${F_AMI_ID}' is not available in region: '${REGION}'"
    fi

    if [[ ! -f ${F_NEW_SSH_KEY} ]]
    then
      cp -f "${F_PUB_KEY}" "${F_NEW_PUB_KEY}"
      cp -f "${F_SSH_KEY}" "${F_NEW_SSH_KEY}"
    fi

    F_CHECK=$(terraform workspace show | grep -q "${F_PROJECTNAME}" \
                && echo $? \
                || echo $? )
    if [[ ${F_CHECK} -eq 0 ]]
    then
        terraform workspace select "${F_PROJECTNAME}"
    else
        terraform workspace new "${F_PROJECTNAME}"
    fi
        
    terraform init
    
    terraform apply -auto-approve \
        -var="os=${F_OSNAME}" \
        -var="ami_id=${F_AMI_ID}" \
        -var="aws_region=${F_REGION}" \
        -var="instance_count=${F_INSTANCES}" \
        -var="ssh_key_path=./${F_NEW_PUB_KEY}" \
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
        
    if [[ ! -f ${F_PROJECT_DIR}/${F_NEW_SSH_KEY} ]]
    then
      mv -f ${DIRECTORY}/terraform/aws/${F_NEW_PUB_KEY} \
            ${F_PROJECT_DIR}/${F_NEW_PUB_KEY}
      mv -f ${DIRECTORY}/terraform/aws/${F_NEW_SSH_KEY} \
            ${F_PROJECT_DIR}/${F_NEW_SSH_KEY}    
    fi
}


################################################################################
# function destroy server
################################################################################
function aws_destroy_server()
{
    local F_REGION="$1"
    local F_PROJECTNAME="$2"
    local F_PROJECT_DIR="$3"

    process_log "Removing AWS Servers"
    cd ${DIRECTORY}/terraform/aws || exit 1

    terraform workspace select "${F_PROJECTNAME}"
        
    terraform destroy -auto-approve \
        -var="aws_region=${F_REGION}"

    terraform workspace select default
    terraform workspace delete "${F_PROJECTNAME}"
    
    rm -Rf ${F_PROJECT_DIR}
}

