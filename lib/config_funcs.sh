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
    local F_CONFIG_FILE="$1"
    local F_MESSAGE="$2"
    local F_IS_NUMBER="$3"
    local F_PARAM="$4"

    local F_READ_INPUT="read -r -e -p"
    local F_READ_SILENT_INPUT="read -s -r -e -p"
    local F_VALUE
    local F_CHECK

    F_CHECK=$(check_variable "${F_PARAM}" "${F_CONFIG_FILE}")
    if [[ "${F_CHECK}" = "not_exists" ]] || [[ "${F_CHECK}" = "exists_empty" ]]
    then
        if [[ "${F_PARAM}" = "YUM_PASSWORD" ]] || [[ "${F_PARAM}" = "ROUTE53_SECRET" ]]
        then
          ${F_READ_SILENT_INPUT} "${F_MESSAGE}" F_VALUE
          echo ""
        else
          ${F_READ_INPUT} "${F_MESSAGE}" F_VALUE
          echo ""
        fi
        if [[ -z ${F_VALUE} ]]
        then
             exit_on_error "Entered value cannot be empty"
        fi
        if [[ "${F_IS_NUMBER}" = "Yes" ]]
        then
            if ! [[ "${F_VALUE}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
            then
                exit_on_error "${F_PARAM} value cannot be string"
            fi
        fi
        if [[ "${F_PARAM}" = "INSTANCE_COUNT" ]]
        then
            if [[ "${F_VALUE}" -lt 1 ]]
            then
                exit_on_error "Instance count cannot be less than 1"
            fi
        fi
        if [[ "${F_PARAM}" = "PEMSERVER" ]]
        then
            F_VALUE=$(echo ${F_VALUE}|tr '[:upper:]' '[:lower:]')
            if [[ "${F_VALUE}" = "yes" ]]
            then
                INSTANCE_COUNT=$(grep INSTANCE_COUNT ${F_CONFIG_FILE} \
                                    |cut -d"=" -f2)
                if [[ "x${INSTANCE_COUNT}" = "x" ]]
                then
                    INSTANCE_COUNT=1
                else
                    INSTANCE_COUNT=$(( INSTANCE_COUNT + 1 ))
                fi
                validate_variable "INSTANCE_COUNT" \
                                  "${F_CONFIG_FILE}"  \
                                  "${INSTANCE_COUNT}"
                PEM_INSTANCE_COUNT=1
                validate_variable "PEM_INSTANCE_COUNT" \
                                  "${F_CONFIG_FILE}"  \
                                  "${PEM_INSTANCE_COUNT}"
            fi

            if [[ "${F_VALUE}" = "no" ]]
            then
                INSTANCE_COUNT=$(grep INSTANCE_COUNT ${F_CONFIG_FILE} \
                                    |cut -d"=" -f2)
                if [[ "x${INSTANCE_COUNT}" = "x" ]]
                then
                    INSTANCE_COUNT=1
                else
                    INSTANCE_COUNT=$(( INSTANCE_COUNT ))
                fi
                validate_variable "INSTANCE_COUNT" \
                                  "${F_CONFIG_FILE}"  \
                                  "${INSTANCE_COUNT}"
                PEM_INSTANCE_COUNT=0
                validate_variable "PEM_INSTANCE_COUNT" \
                                  "${F_CONFIG_FILE}"  \
                                  "${PEM_INSTANCE_COUNT}"
            fi
        fi
        if [[ "${F_PARAM}" = "PG_VERSION" ]]
        then
            if [[ "${F_VALUE}" -lt 10 ]]
            then
                exit_on_error "Instance count cannot be less than 10"
            fi
            if [[ "${F_VALUE}" -gt 12 ]]
            then
                exit_on_error "Instance count cannot be less than 10"
            fi            
        fi        
        validate_variable "${F_PARAM}" "${F_CONFIG_FILE}" "${F_VALUE}"
    fi
}

################################################################################
# function: Check if we have configurations or not and prompt accordingly
################################################################################
function aws_config_file()
{
    local PROJECT_NAME="$1"
    local F_PROJECT_DIR="$2"

    local F_REGION
    local F_OPTION
    local F_MESSAGE
    local F_LOOP_VAR

    local F_CONFIG_FILE="${F_PROJECT_DIR}/${PROJECT_NAME}.cfg"
    local F_READ_INPUT="read -r -e -p"

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}    

    if [[ ! -f ${F_CONFIG_FILE} ]]
    then
       touch ${F_CONFIG_FILE}
       chmod 600 ${F_CONFIG_FILE}
    else
        source ${F_CONFIG_FILE}
    fi
     
    validate_variable "OSNAME" "${F_CONFIG_FILE}" "CentOS8"
    validate_variable "INSTANCE_COUNT" "${F_CONFIG_FILE}" "4"
    validate_variable "PEM_INSTANCE_COUNT" "${F_CONFIG_FILE}" "1"
    validate_variable "PEMSERVER" "${F_CONFIG_FILE}" "yes"
    validate_variable "STANDBY_TYPE" "${F_CONFIG_FILE}" "asynchronous"
    validate_variable "PG_TYPE" "${F_CONFIG_FILE}" "EPAS"
    validate_variable "PG_VERSION" "${F_CONFIG_FILE}" "12"
    set +u 
    F_CHECK=$(check_variable "REGION" "${F_CONFIG_FILE}")
    if [[ "${F_CHECK}" = "not_exists" ]] || [[ "${F_CHECK}" = "exists_empty" ]]
    then
      F_LOOP_VAR=0
    else
      F_LOOP_VAR=1
      F_REGION="${REGION}"
    fi
    if [[ ${F_LOOP_VAR} -eq 0 ]]
    then
      echo "Please provie the target AWS region from the list"
      echo " 1. us-east-1"
      echo " 2. us-east-2"
      echo " 3. us-west-1"
      echo " 4. us-west-2"
    fi
    while [[ ${F_LOOP_VAR} -eq 0 ]]
    do
      read -r -e -p "Please enter your numeric choice: " F_OPTION
      echo ""

      F_OPTION=$(echo ${F_OPTION}|tr '[:upper:]' '[:lower:]')

      case "${F_OPTION}" in
        1)
          F_REGION="us-east-1"
          break
          ;;
        2)
          F_REGION="us-east-2"
          break
          ;;
        3)
          F_REGION="us-west-1"
          break
          ;;
        4)
          F_REGION="us-west-2"
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
    validate_variable "REGION" "${F_CONFIG_FILE}" "${F_REGION}"

    ################################################################################
    # Prompt for ssh private key options
    ################################################################################
    F_CHECK=$(check_variable "PRIV_FILE_PATH" "${F_CONFIG_FILE}")
    if [[ "${F_CHECK}" = "not_exists" ]] || [[ "${F_CHECK}" = "exists_empty" ]]
    then
      F_LOOP_VAR=0
    else
      F_LOOP_VAR=1
      F_PRIV_FILE_PATH="${PRIV_FILE_PATH}"
    fi
    while [[ ${F_LOOP_VAR} -eq 0 ]]
    do
      echo "Provide the absolute path of private key file"
      read -r -e -p "  [${HOME}/.ssh/id_rsa]: " F_OPTION
      echo ""
      if [[ "${F_OPTION}" = "" ]]
      then
        F_PRIV_FILE_PATH="${HOME}/.ssh/id_rsa"
      else
        F_PRIV_FILE_PATH="${F_OPTION}"
      fi

      if [[ ! -f "${F_PRIV_FILE_PATH}" ]]
      then
        echo "${F_PRIV_FILE_PATH} does not exists."
        read -r -e  -p "Do you want to create a one enter Yes/No or 'exit' to quit: " F_OPTION
        F_OPTION=$(echo ${F_OPTION}|tr '[:upper:]' '[:lower:]')
        if [[ "${F_OPTION}" = "yes" ]]
        then
          ssh-keygen -q -t rsa -f ${F_PRIV_FILE_PATH}  -C "" -N ""
          break
        elif [[ "${F_OPTION}" = "exit" ]]
        then
          exit 0
        fi
      else
        break
      fi
    done
    validate_variable "PRIV_FILE_PATH" "${F_CONFIG_FILE}" "${F_PRIV_FILE_PATH}"

    ################################################################################
    # Prompt for ssh public key options
    ################################################################################
    F_CHECK=$(check_variable "PUB_FILE_PATH" "${F_CONFIG_FILE}")
    if [[ "${F_CHECK}" = "not_exists" ]] || [[ "${F_CHECK}" = "exists_empty" ]]
    then
      F_LOOP_VAR=0
    else
      F_LOOP_VAR=1
      F_PUB_FILE_PATH="${PUB_FILE_PATH}"
    fi
    while [[ ${F_LOOP_VAR} -eq 0 ]]
    do
      echo "Provide the absolute path of public key file"
      echo ""
      read -r -e -p "   [${HOME}/.ssh/id_rsa.pub]: " F_OPTION
      if [[ "${F_OPTION}" = "" ]]
      then
        F_PUB_FILE_PATH="${HOME}/.ssh/id_rsa.pub"
      else
        F_PUB_FILE_PATH="${F_OPTION}"
      fi

      if [[ ! -f ${F_PUB_FILE_PATH} ]]
      then
        echo "${F_PUB_FILE_PATH} does not exists."
        read -r -e  -p "Do you want to create a one enter Yes/No or 'exit' to quit: " F_OPTION
        F_OPTION=$(echo ${F_OPTION}|tr '[:upper:]' '[:lower:]')
        if [[ "${F_OPTION}" = "yes" ]]
        then
          ssh-keygen -q -t rsa -f ${F_PUB_FILE_PATH}  -C "" -N ""
          break
        elif [[ "${F_OPTION}" = "exit" ]]
        then
          exit 0
        fi
      else
        break
      fi
    done
    validate_variable "PUB_FILE_PATH" "${F_CONFIG_FILE}" "${F_PUB_FILE_PATH}"
    F_MESSAGE="Provide EDB yum username: "
    check_update_param "${F_CONFIG_FILE}" "${F_MESSAGE}" "No" "YUM_USERNAME"
    F_MESSAGE="Provide EDB yum password: "
    check_update_param "${F_CONFIG_FILE}" "${F_MESSAGE}" "No" "YUM_PASSWORD"
    F_MESSAGE="Provide your email id: "
    check_update_param "${F_CONFIG_FILE}" "${F_MESSAGE}" "No" "EMAIL_ID"
    F_MESSAGE="Provide route53 access key: "
    check_update_param "${F_CONFIG_FILE}" "${F_MESSAGE}" "No" "ROUTE53_ACCESS_KEY"
    F_MESSAGE="Provide route53 secret: "
    check_update_param "${F_CONFIG_FILE}" "${F_MESSAGE}" "No" "ROUTE53_SECRET"
    set -u

    process_log "set all parameters"
    source ${F_CONFIG_FILE}
}


function aws_show_config_file()
{
    local F_PROJECTNAME="$1"
    local F_PROJECT_DIR="$2"

    local F_SHOW
    local F_CONFIGFILE="${F_PROJECT_DIR}/${F_PROJECTNAME}.cfg"

    F_SHOW="$(echo cat ${F_CONFIGFILE})"    
    eval "${F_SHOW}"

    process_log "showed aws project config details"
}


function aws_update_config_file()
{
    local F_PROJECTNAME="$1"
    local F_PROJECT_DIR="$2"
    local F_CONFIGFILE="${F_PROJECT_DIR}/${PROJECT_NAME}.cfg"
    local F_EDIT

    F_EDIT="$(echo vi ${F_CONFIGFILE})"    
    eval "${F_EDIT}"

    process_log "edited aws project config details"
}


function aws_list_projects()
{
    local F_LIST_PROJECTS
    echo "AWS Terraform Projects:"
    cd ${DIRECTORY}/terraform/aws || exit 1
    F_LIST_PROJECTS="$(echo terraform workspace list)"
    eval "${F_LIST_PROJECTS}"

    process_log "listed all aws projects"
}


function aws_switch_projects()
{
    local F_PROJECTNAME="$1"
    local F_SWITCH_PROJECT

    cd ${DIRECTORY}/terraform/aws || exit 1
    F_SWITCH_PROJECT="$(echo terraform workspace select ${F_PROJECTNAME})"
    eval "${F_SWITCH_PROJECT}"

    process_log "switched to aws project: ${F_PROJECTNAME}"
}
