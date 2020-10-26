#! /bin/bash
################################################################################
# Title           : config_funcs script to capture the users argument and
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
# function: check the param passed by the user
################################################################################
function check_update_param()
{
    local CONFIG_FILE="$1"
    local MESSAGE="$2"
    local IS_NUMBER="$3"
    local PARAM="$4"

    local READ_INPUT="read -r -e -p"
    local MSG_SUFFIX="PID: $$ [$(date +'%m-%d-%y %H:%M:%S')]: "
    local VALUE
    local CHECK

    CHECK=$(check_variable "${PARAM}" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        ${READ_INPUT} "${MSG_SUFFIX}${MESSAGE}" VALUE
        if [[ -z ${VALUE} ]]
        then
             exit_on_error "Entered value cannot be empty"
        fi
        if [[ "${IS_NUMBER}" = "Yes" ]]
        then
            if ! [[ "${VALUE}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
            then
                exit_on_error "${PARAM} value cannot be string"
            fi
        fi
        if [[ "${PARAM}" = "INSTANCE_COUNT" ]]
        then
            if [[ "${VALUE}" -lt 1 ]]
            then
                exit_on_error "Instance count cannot be less than 1"
            fi
        fi
        if [[ "${PARAM}" = "PEMSERVER" ]]
        then
            VALUE=$(echo ${VALUE}|tr '[:upper:]' '[:lower:]')
            if [[ "${VALUE}" = "yes" ]]
            then
                INSTANCE_COUNT=$(grep INSTANCE_COUNT ${CONFIG_FILE} \
                                    |cut -d"=" -f2)
                if [[ "x${INSTANCE_COUNT}" = "x" ]]
                then
                    INSTANCE_COUNT=1
                else
                    INSTANCE_COUNT=$(( INSTANCE_COUNT + 1 ))
                fi
                validate_variable "INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${INSTANCE_COUNT}"
                PEM_INSTANCE_COUNT=1
                validate_variable "PEM_INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${PEM_INSTANCE_COUNT}"
            fi

            if [[ "${VALUE}" = "no" ]]
            then
                INSTANCE_COUNT=$(grep INSTANCE_COUNT ${CONFIG_FILE} \
                                    |cut -d"=" -f2)
                if [[ "x${INSTANCE_COUNT}" = "x" ]]
                then
                    INSTANCE_COUNT=1
                else
                    INSTANCE_COUNT=$(( INSTANCE_COUNT ))
                fi
                validate_variable "INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${INSTANCE_COUNT}"
                PEM_INSTANCE_COUNT=0
                validate_variable "PEM_INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${PEM_INSTANCE_COUNT}"
            fi
        fi
        if [[ "${PARAM}" = "PG_VERSION" ]]
        then
            if [[ "${VALUE}" -lt 10 ]]
            then
                exit_on_error "Instance count cannot be less than 10"
            fi
            if [[ "${VALUE}" -gt 12 ]]
            then
                exit_on_error "Instance count cannot be less than 10"
            fi            
        fi        
        validate_variable "${PARAM}" "${CONFIG_FILE}" "${VALUE}"
    fi
}

################################################################################
# function: Check if we have configurations or not and prompt accordingly
################################################################################
function aws_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"
    #local RESULT=""

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}    

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi
    
    set +u

    # Prompt for OSNAME
    CHECK=$(check_variable "OSNAME" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. CentOS 7' '2. CentOS 8' '3. RHEL 7' '4. RHEL 8')
        declare -a CHOICES=('1' '2' '3' '4')
        
        RESULT=""
        custom_options_prompt "Which Operating System would you like to Install?" OPTIONS CHOICES RESULT
        case "${RESULT}" in
          1)
            OSNAME="CentOS7"
            ;;
          2)
            OSNAME="CentOS8"
            ;;
          3)
            OSNAME="RHEL7"
            ;;
          4)
            OSNAME="RHEL8"
            ;;
      esac
    fi
    export OSNAME
    validate_variable "OSNAME" "${CONFIG_FILE}" "${OSNAME}"
    
    # Prompt for REGION
    CHECK=$(check_variable "REGION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. us-east-1' '2. us-east-2' '3. us-west-1' '4. us-west-2')
        declare -a CHOICES=('1' '2' '3' '4')
        
        RESULT=""
        custom_options_prompt "Which Region would you like to use?" OPTIONS CHOICES RESULT
        case "${RESULT}" in
          1)
            REGION="us-east-1"
            ;;
          2)
            REGION="us-east-2"
            ;;
          3)
            REGION="us-west-1"
            ;;
          4)
            REGION="us-west-2"
            ;;
        esac   
    fi
    export REGION
    validate_variable "REGION" "${CONFIG_FILE}" "${REGION}"


    CHECK=$(check_variable "INSTANCE_COUNT" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Single Installation' '2. Multi-Node Installation')
        declare -a CHOICES=('1' '2')
        
        RESULT=""
        custom_options_prompt "How many AWS EC2 Instances would you like to create?" OPTIONS CHOICES RESULT
        case "${RESULT}" in
          1)
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "0"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "No"
            ;;
          2)
            # Ask about how many instances for multi-node cluster
            RESULT=""
            validate_string_not_empty "Please enter how many AWS EC2 Instances you would like for the Multi-Node Cluster? " "" RESULT
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "${RESULT}"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "Yes"
            ;;
        esac
    fi
    export STANDBY_TYPE
    validate_variable "STANDBY_TYPE" "${CONFIG_FILE}" "${STANDBY_TYPE}"      
    
    # Public Key File
    CHECK=$(check_variable "PUB_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "What will the absolute path of the public key file be?" "[${HOME}/.ssh/id_rsa.pub]: " RESULT
        PUB_FILE_PATH="${RESULT}"
    fi
    validate_variable "PUB_FILE_PATH" "${CONFIG_FILE}" "${PUB_FILE_PATH}"

    # Private Key File
    CHECK=$(check_variable "PRIV_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "What will the absolute path of the private key file be?" "[${HOME}/.ssh/id_rsa]: " RESULT
        PRIV_FILE_PATH="${RESULT}"
    fi
    validate_variable "PRIV_FILE_PATH" "${CONFIG_FILE}" "${PRIV_FILE_PATH}"
      
    # Prompt for Database Engine
    CHECK=$(check_variable "PG_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Postgres' '2. EDB Postgres Advanced Server')
        declare -a CHOICES=('1' '2')
        
        RESULT=""
        echo "${options[@]}"
        custom_options_prompt "Which Database Engine would you like to install?" OPTIONS CHOICES RESULT
        case "${RESULT}" in
          1)
            PG_TYPE="PG"
            ;;
          2)
            PG_TYPE="EPAS"
            ;;
        esac
    fi
    export PG_TYPE
    validate_variable "PG_TYPE" "${CONFIG_FILE}" "${PG_TYPE}"

    # Prompt for Database Engine Version
    CHECK=$(check_variable "PG_VERSION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. 10' '2. 11' '3. 12')
        declare -a CHOICES=('1' '2' '3')
        
        RESULT=""
        custom_options_prompt "Which Database Version do you wish to install?" OPTIONS CHOICES RESULT
        case "${RESULT}" in
          1)
            PG_VERSION="10"
            break
            ;;
          2)
            PG_VERSION="11"
            ;;
          3)
            PG_VERSION="12"
            ;;          
        esac
    fi
    export PG_VERSION
    validate_variable "PG_VERSION" "${CONFIG_FILE}" "${PG_VERSION}"  
  
    # Prompt for Standby Replication Type
    CHECK=$(check_variable "STANDBY_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. synchronous' '2. asynchronous')
        declare -a CHOICES=('1' '2')
        
        RESULT=""
        custom_options_prompt "Which type of replication would you like for standby nodes?" OPTIONS CHOICES RESULT
        case "${RESULT}" in
          1)
            STANDBY_TYPE="synchronous"
            ;;
          2)
            STANDBY_TYPE="asynchronous"
            ;;
        esac
    fi
    export STANDBY_TYPE
    validate_variable "STANDBY_TYPE" "${CONFIG_FILE}" "${STANDBY_TYPE}"      

    # AMI ID
    CHECK=$(check_variable "AMI_ID" "${CONFIG_FILE}")    
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        custom_yesno_prompt "Do you want to utilize an AMI ID for the Instances?" "Enter: (Y)es/(N)o" RESULT
        if [[ "${RESULT}" = "Yes" ]]
        then
            RESULT=""
            validate_string_not_empty "Please enter the AMI ID: " "" RESULT
            AMI_ID="${RESULT}"
        else
            AMI_ID="${RESULT}"
        fi
    fi
    validate_variable "AMI_ID" "${CONFIG_FILE}" "${AMI_ID}"

    # EDB YUM UserName
    CHECK=$(check_variable "YUM_USERNAME" "${CONFIG_FILE}")    
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "Please provide EDB Yum Username: " "" RESULT
        YUM_USERNAME="${RESULT}"
    fi
    validate_variable "YUM_USERNAME" "${CONFIG_FILE}" "${YUM_USERNAME}"
    
    # EDB YUM Password
    CHECK=$(check_variable "YUM_PASSWORD" "${CONFIG_FILE}")    
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_password_not_empty "Please provide EDB Yum Password: " "" RESULT
        YUM_PASSWORD="${RESULT}"
    fi
    validate_variable "YUM_PASSWORD" "${CONFIG_FILE}" "${YUM_PASSWORD}"
    
    set -u
        
    process_log "set all parameters"
    source ${CONFIG_FILE}
}

function azure_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}/${PROJECT_NAME}.cfg"    
    local READ_INPUT="read -r -e -p"

    local MESSAGE

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}        

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi

    MESSAGE="Please provide Publisher from 'OpenLogic/RedHat': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PUBLISHER"
     
    MESSAGE="Please provide OS name from 'Centos/RHEL': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "OFFER"

    MESSAGE="Please provide OS version from 'Centos - 7.7 or 8_1/RHEL - 7.8 or 8.2': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "SKU"

    MESSAGE="Please provide target Azure Location"
    MESSAGE="${MESSAGE} examples: 'centralus', 'eastus', 'eastus2', 'westus', 'westcentralus', 'westus2', 'northcentralus' or 'southcentralus': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "LOCATION"
   
    MESSAGE="Please provide how many Azure Instances to create"
    MESSAGE="${MESSAGE} example '>=1': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "Yes" "INSTANCE_COUNT"

    MESSAGE="Please indicate if you would like a PEM Server Instance"
    MESSAGE="${MESSAGE} Yes/No': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PEMSERVER"

    MESSAGE="Provide: Absolute path of public key file, example:"
    MESSAGE="${MESSAGE}  '~/.ssh/id_rsa.pub': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PUB_FILE_PATH"

    MESSAGE="Provide: Absolute path of private key file, example:"
    MESSAGE="${MESSAGE}  '~/.ssh/id_rsa': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PRIV_FILE_PATH"
 
    MESSAGE="Please provide Postgresql DB Engine. PG/EPAS: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PG_TYPE"

    MESSAGE="Please provide Postgresql DB Version."
    MESSAGE="${MESSAGE} Options are 10, 11 or 12: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PG_VERSION"
 
    MESSAGE="Provide: Type of Replication: 'synchronous' or 'asynchronous': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "STANDBY_TYPE"

    MESSAGE="Provide EDB Yum Username: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "YUM_USERNAME"

    MESSAGE="Provide EDB Yum Password: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "YUM_PASSWORD"

    process_log "set all parameters"
    source ${CONFIG_FILE}
}

function gcloud_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}/${PROJECT_NAME}.cfg"    
    local READ_INPUT="read -r -e -p"

    local MESSAGE

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi

    MESSAGE="Please provide OS name from 'centos-7, centos-8, rhel-7 and rhel-8': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "OSNAME"

    MESSAGE="Please Google Project ID: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PROJECT_ID"
    
    MESSAGE="Please provide target Google Cloud Region"
    MESSAGE="${MESSAGE} examples: 'us-central1', 'us-east1', 'us-east4', 'us-west1', 'us-west2', 'us-west3' or 'us-west4': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "SUBNETWORK_REGION"
   
    MESSAGE="Please provide how many VM Instances to create"
    MESSAGE="${MESSAGE} example '>=1': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "Yes" "INSTANCE_COUNT"

    MESSAGE="Please indicate if you would like a PEM Server Instance"
    MESSAGE="${MESSAGE} Yes/No': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PEMSERVER"

    MESSAGE="Please provide absolute path of the credentials json file"
    MESSAGE="${MESSAGE} example '~/accounts.json': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "CREDENTIALS_FILE_LOCATION"

    MESSAGE="Provide: Absolute path of public key file, example:"
    MESSAGE="${MESSAGE}  '~/.ssh/id_rsa.pub': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PUB_FILE_PATH"

    MESSAGE="Provide: Absolute path of private key file, example:"
    MESSAGE="${MESSAGE}  '~/.ssh/id_rsa': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PRIV_FILE_PATH"
 
    MESSAGE="Please provide Postgresql DB Engine. PG/EPAS: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PG_TYPE"

    MESSAGE="Please provide Postgresql DB Version."
    MESSAGE="${MESSAGE} Options are 10, 11 or 12: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PG_VERSION"
 
    MESSAGE="Provide: Type of Replication: 'synchronous' or 'asynchronous': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "STANDBY_TYPE"

    MESSAGE="Provide EDB Yum Username: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "YUM_USERNAME"

    MESSAGE="Provide EDB Yum Password: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "YUM_PASSWORD"

    process_log "set all parameters"
    source ${CONFIG_FILE}
}

function aws_show_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    SHOW="$(echo cat ${CONFIG_FILE})"    
    eval "$SHOW"

    process_log "showed aws project config details"
}

function azure_show_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    SHOW="$(echo cat ${CONFIG_FILE})"    
    eval "$SHOW"

    process_log "showed azure project config details"
}

function gcloud_show_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    SHOW="$(echo cat ${CONFIG_FILE})"    
    eval "$SHOW"

    process_log "showed gcloud project config details"
}

function aws_update_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    EDIT="$(echo vi ${CONFIG_FILE})"    
    eval "$EDIT"

    process_log "edited aws project config details"
}

function azure_update_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    EDIT="$(echo vi ${CONFIG_FILE})"    
    eval "$EDIT"

    process_log "edited azure project config details"
}

function gcloud_update_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    EDIT="$(echo vi ${CONFIG_FILE})"    
    eval "$EDIT"

    process_log "edited gcloud project config details"
}

function aws_list_projects()
{
    echo "AWS Terraform Projects:"
    cd ${DIRECTORY}/terraform/aws || exit 1
    LIST_PROJECTS="$(echo terraform workspace list)"
    eval "$LIST_PROJECTS"

    process_log "listed all aws projects"
}

function azure_list_projects()
{
    echo "Azure Terraform Projects:"
    cd ${DIRECTORY}/terraform/azure || exit 1
    LIST_PROJECTS="$(echo terraform workspace list)"
    eval "$LIST_PROJECTS"

    process_log "listed all azure projects"
}

function gcloud_list_projects()
{
    echo "GCloud Terraform Projects:"
    cd ${DIRECTORY}/terraform/gcloud || exit 1
    LIST_PROJECTS="$(echo terraform workspace list)"
    eval "$LIST_PROJECTS"

    process_log "listed all GCloud projects"
}

function aws_switch_projects()
{
    local PROJECT_NAME="$1"

    cd ${DIRECTORY}/terraform/aws || exit 1
    SWITCH_PROJECT="$(echo terraform workspace select ${PROJECT_NAME})"
    eval "$SWITCH_PROJECT"

    process_log "switched to aws project: ${PROJECT_NAME}"
}

function azure_switch_projects()
{
    local PROJECT_NAME="$1"

    cd ${DIRECTORY}/terraform/azure || exit 1
    SWITCH_PROJECT="$(echo terraform workspace select ${PROJECT_NAME})"
    eval "$SWITCH_PROJECT"

    process_log "switched to azure project: ${PROJECT_NAME}"
}

function gcloud_switch_projects()
{
    local PROJECT_NAME="$1"

    cd ${DIRECTORY}/terraform/gcloud || exit 1
    SWITCH_PROJECT="$(echo terraform workspace select ${PROJECT_NAME})"
    eval "$SWITCH_PROJECT"

    process_log "switched to gcloud project: ${PROJECT_NAME}"
}
