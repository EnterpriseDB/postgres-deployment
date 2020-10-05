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
            if [[ "${VALUE}" -lt 3 ]]
            then
                exit_on_error "Instance count cannot be less than 3"
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
        validate_variable "${PARAM}" "${CONFIG_FILE}" "${VALUE}"
    fi
}

################################################################################
# function: Check if we have configurations or not and prompt accordingly
################################################################################
function aws_config_file()
{
    local PROJECT_NAME="$1"
    #local CONFIG_FILE="${CONFIG_DIR}/${PROJECT_NAME}.cfg"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"
    local READ_INPUT="read -r -e -p"

    local MESSAGE

    mkdir -p ${LOGDIR}
    #mkdir -p ${CONFIG_DIR}
    mkdir -p ${PROJECTS_DIRECTORY}/${PROJECT_NAME}    

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi
     
    MESSAGE="Please provide OS name from 'CentOS7/CentOS8/RHEL7/RHEL8': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "OSNAME"

    MESSAGE="Please provide target AWS Region"
    MESSAGE="${MESSAGE} examples: 'us-east-1', 'us-east-2', 'us-west-1'or 'us-west-2': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "REGION"
   
    MESSAGE="Please provide how many AWS EC2 Instances to create"
    MESSAGE="${MESSAGE} example '>=3': "
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

function azure_config_file()
{
    local PROJECT_NAME="$1"
    #local CONFIG_FILE="${CONFIG_DIR}/${PROJECT_NAME}.cfg"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}/${PROJECT_NAME}.cfg"    
    local READ_INPUT="read -r -e -p"

    local MESSAGE

    mkdir -p ${LOGDIR}
    #mkdir -p ${CONFIG_DIR}
    mkdir -p ${PROJECTS_DIRECTORY}/${PROJECT_NAME}        

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
    MESSAGE="${MESSAGE} example '>=3': "
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
    #local CONFIG_FILE="${CONFIG_DIR}/${PROJECT_NAME}.cfg"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}/${PROJECT_NAME}.cfg"    
    local READ_INPUT="read -r -e -p"

    local MESSAGE

    mkdir -p ${LOGDIR}
    #mkdir -p ${CONFIG_DIR}
    mkdir -p ${PROJECTS_DIRECTORY}/${PROJECT_NAME}

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi

    MESSAGE="Please provide OS name from 'CentOS7/RHEL7': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "OSNAME"

    MESSAGE="Please Google Project ID: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "PROJECT_ID"
    
    MESSAGE="Please provide target Google Cloud Region"
    MESSAGE="${MESSAGE} examples: 'us-centarl1', 'us-east1', 'us-east4', 'us-west1', 'us-west2', 'us-west3' or 'us-west4': "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "SUBNETWORK_REGION"
   
    MESSAGE="Please provide how many VM Instances to create"
    MESSAGE="${MESSAGE} example '>=3': "
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
