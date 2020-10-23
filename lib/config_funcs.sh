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
        ${READ_INPUT} "${MESSAGE}" VALUE
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
    local READ_INPUT="read -r -e -p"

    local MESSAGE
    local loop_var

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}    

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi
     
    validate_variable "OSNAME" "${CONFIG_FILE}" "CentOS8"
    validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "4"
    validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "1"
    validate_variable "PEMSERVER" "${CONFIG_FILE}" "yes"
    validate_variable "STANDBY_TYPE" "${CONFIG_FILE}" "asynchronous"
    validate_variable "PG_TYPE" "${CONFIG_FILE}" "EPAS"
    validate_variable "PG_VERSION" "${CONFIG_FILE}" "12"
    set +u 
    CHECK=$(check_variable "REGION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
      loop_var=0
    else
      loop_var=1
    fi
    if [[ ${loop_var} -eq 0 ]]
    then
      echo "Please provie the target AWS region from the list"
      echo " 1. us-east-1"
      echo " 2. us-east-2"
      echo " 3. us-west-1"
      echo " 4. us-west-2"
    fi
    while [[ ${loop_var} -eq 0 ]]
    do
      if [[  "x${REGION}" = "x" ]]
      then
        read -r -e -p "Please enter your numeric choice: " OPTION
      else
        read -r -e -p "Please enter your numeric choice [${REGION}]: " OPTION
      fi

      OPTION=$(echo ${OPTION}|tr '[:upper:]' '[:lower:]')

      case "${OPTION}" in
        1)
          REGION="us-east-1"
          break
          ;;
        2)
          REGION="us-east-2"
          break
          ;;
        3)
          REGION="us-west-1"
          break
          ;;
        4)
          REGION="us-west-2"
          break
          ;;
        "exit")
          exit 0
          ;;
        *)
          echo "Unknown option. enter a number 1-4 or type 'exit' to quit: "
          ;;
      esac
    done
    export REGION
    validate_variable "REGION" "${CONFIG_FILE}" "${REGION}"

    ################################################################################
    # Prompt for ssh private key options
    ################################################################################
    CHECK=$(check_variable "PRIV_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
      loop_var=0
    else
      loop_var=1
    fi
    while [[ ${loop_var} -eq 0 ]]
    do
      echo "Provide the absolute path of private key file"
      read -r -e -p "[${HOME}/.ssh/id_rsa]: " OPTION
      if [[ "${OPTION}" = "" ]]
      then
        PRIV_FILE_PATH="${HOME}/.ssh/id_rsa"
      else
        PRIV_FILE_PATH="${OPTION}"
      fi

      if [[ ! -f "${PRIV_FILE_PATH}" ]]
      then
        echo "${PRIV_FILE_PATH} does not exists."
        read -r -e  -p "Do you want to create a one enter Yes/No or 'exit' to quit: " OPTION
        OPTION=$(echo ${VALUE}|tr '[:upper:]' '[:lower:]')
        if [[ "${OPTION}" = "yes" ]]
        then
          ssh-keygen -q -t rsa -f ${PRIV_FILE_PATH}  -C "" -N ""
          break
        elif [[ "${OPTION}" = "exit" ]]
        then
          exit 0
        fi
      else
        break
      fi
    done
    validate_variable "PRIV_FILE_PATH" "${CONFIG_FILE}" "${PRIV_FILE_PATH}"

    ################################################################################
    # Prompt for ssh public key options
    ################################################################################
    CHECK=$(check_variable "PUB_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
      loop_var=0
    else
      loop_var=1
    fi
    while [[ ${loop_var} -eq 0 ]]
    do
      echo "Provide the absolute path of public key file"
      read -r -e -p "[${HOME}/.ssh/id_rsa.pub]: " OPTION
      if [[ "${OPTION}" = "" ]]
      then
        PUB_FILE_PATH="${HOME}/.ssh/id_rsa.pub"
      else
        PUB_FILE_PATH="${OPTION}"
      fi

      if [[ ! -f ${PUB_FILE_PATH} ]]
      then
        echo "${PUB_FILE_PATH} does not exists."
        read -r -e  -p "Do you want to create a one enter Yes/No or 'exit' to quit: " OPTION
        OPTION=$(echo ${VALUE}|tr '[:upper:]' '[:lower:]')
        if [[ "${OPTION}" = "yes" ]]
        then
          ssh-keygen -q -t rsa -f ${PUB_FILE_PATH}  -C "" -N ""
          break
        elif [[ "${OPTION}" = "exit" ]]
        then
          exit 0
        fi
      else
        break
      fi
    done
    validate_variable "PUB_FILE_PATH" "${CONFIG_FILE}" "${PUB_FILE_PATH}"

    MESSAGE="Provide EDB yum username: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "YUM_USERNAME"

    MESSAGE="Provide EDB yum password: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "YUM_PASSWORD"

    MESSAGE="Provide your email id: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "EmailId"

    MESSAGE="Provide route53 access key: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "ROUTE53_ACCESS_KEY"

    MESSAGE="Provide route53 secret: "
    check_update_param "${CONFIG_FILE}" "${MESSAGE}" "No" "ROUTE53_SECRET"
    set -u

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


function aws_update_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    EDIT="$(echo vi ${CONFIG_FILE})"    
    eval "$EDIT"

    process_log "edited aws project config details"
}


function aws_list_projects()
{
    echo "AWS Terraform Projects:"
    cd ${DIRECTORY}/terraform/aws || exit 1
    LIST_PROJECTS="$(echo terraform workspace list)"
    eval "$LIST_PROJECTS"

    process_log "listed all aws projects"
}


function aws_switch_projects()
{
    local PROJECT_NAME="$1"

    cd ${DIRECTORY}/terraform/aws || exit 1
    SWITCH_PROJECT="$(echo terraform workspace select ${PROJECT_NAME})"
    eval "$SWITCH_PROJECT"

    process_log "switched to aws project: ${PROJECT_NAME}"
}
