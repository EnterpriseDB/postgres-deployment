#! /bin/bash
################################################################################
# Title           : Common function for loging and exit_on error
# Author          : Vibhor Kumar
# Date            : Sept 7, 2020
# Version         : 1.0
################################################################################

################################################################################
# quit on any error
set -e
# verify any  undefined shell variables
set -u

################################################################################
# Common variables
################################################################################
DIRECTORY=$(dirname $0)
if [[ "${DIRECTORY}" = "." ]]
then
   DIRECTORY="${PWD}"
fi
LOG_SUFFIX="$(date +'%m-%d-%y-%H%M%S')"
LOGDIR="${DIRECTORY}/log"
INSTALL_LOG="${LOGDIR}/install_${LOG_SUFFIX}.log"
#CONFIG_DIR=~/.edb
TERRAFORM_LOG="${LOGDIR}/terraform_${LOG_SUFFIX}.log"
PG_INSTALL_LOG="${LOGDIR}/pg_install_${LOG_SUFFIX}.log"

################################################################################
# function: print messages with process id
################################################################################
function process_log()
{
   echo "PID: $$ [$(date +'%m-%d-%y %H:%M:%S')]: $*" >&2
}

################################################################################
# function: exit_on_error
################################################################################
function exit_on_error()
{

   process_log "ERROR: $*"
   exit 1
 }

################################################################################
# function to verify if variable exists or not and add accordingly
################################################################################
function check_variable()
{
    local VARIABLE="$1"
    local FILE="$2"
    local CHECK_VARIABLE

    CHECK_VARIABLE=$(grep -q "${VARIABLE}" ${FILE} \
                          && echo $? \
                          || echo $?)
    if [[ "${CHECK_VARIABLE}" -ne 0 ]]
    then
       echo "not_exists"
    elif [[ "${CHECK_VARIABLE}" -eq 0 ]]
    then
        VALUE=$(grep "^${VARIABLE}=" ${FILE} | cut -d"=" -f2)
        if [[ "x${VALUE}" = "x" ]]
        then
            echo "exists_empty"
        else
           echo "exists_not_empty"
        fi
    fi
}

################################################################################
# function to verify if variable exists or not and add accordingly
################################################################################
function validate_variable()
{
    local VARIABLE="$1"
    local FILE="$2"
    local VAR_VALUE="$3"
    local CHECK_VAR
    local OLD_VALUE

    CHECK_VAR=$(check_variable "${VARIABLE}" "${FILE}")

    if [[ "${CHECK_VAR}" = "not_exists" ]]
    then
        echo "${VARIABLE}=${VAR_VALUE}" >> ${FILE}
    elif [[ "${CHECK_VAR}" = "exists_empty" ]]
    then
        sed -i "/${VARIABLE}=/d" ${FILE}
        echo "${VARIABLE}=${VAR_VALUE}" >> ${FILE}
    elif [[ "${CHECK_VAR}" = "exists_not_empty" ]]
    then
        OLD_VALUE=$(grep "^${VARIABLE}=" ${FILE} | cut -d"=" -f2)
        if [[ "${OLD_VALUE}" != "${VAR_VALUE}" ]]
        then
            sed -i "/${VARIABLE}=/d" ${FILE}
            echo "${VARIABLE}=${VAR_VALUE}" >> ${FILE}
        fi
    fi
}

################################################################################
# function for parsing YAML
################################################################################
function parse_yaml {
   set +u
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
   set -u
}

################################################################################
# function for getting filename after last slash
################################################################################
function get_string_after_lastslash {
   set +u
   local filenameandpath=$1
   local F_Result=""
   
   F_Result=$(echo "${filenameandpath##*/}")

   echo "$F_Result"
   set -u
}

################################################################################
# function for getting before after last hyphen
################################################################################
function get_string_before_last_hyphen {
   set +u
   local content=$1
   local F_Result=""
   
   F_Result=$(echo "${content%-*}")

   echo "$F_Result"
   set -u
}

################################################################################
# function for joining two strings separated by underscore
################################################################################
function join_strings_with_underscore {
   set +u
   local string1=$1
   local string2=$2
   local F_Result=""
   
   F_Result="${string1}_${string2}"

   echo "$F_Result"
   set -u
}

################################################################################
# function for getting the first word from an command line output
################################################################################
function get_first_word_from_output {
   set +u
   local text=$1
   local F_Result=""
   
   F_Result=$(echo $text | grep -o "^\S*")

   echo "$F_Result"
   set -u
}

################################################################################
# function for copying files to project directory
################################################################################
function copy_files_to_project_folder {
   set +u
   local cloud=$1
   
   cp -f ${DIRECTORY}/playbook/ansible.cfg ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.
   cp -f ${DIRECTORY}/playbook/playbook*.yml ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.
   cp -f ${DIRECTORY}/playbook/rhel_firewald_rule.yml ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.        
   mv -f ${DIRECTORY}/terraform/${cloud}/hosts.yml ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.
   #mv -f ${DIRECTORY}/terraform/${cloud}/inventory.yml ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.
   mv -f ${DIRECTORY}/terraform/${cloud}/pem-inventory.yml ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.
   mv -f ${DIRECTORY}/terraform/${cloud}/os.csv ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.
   mv -f ${DIRECTORY}/terraform/${cloud}/add_host.sh ${PROJECTS_DIRECTORY}/${cloud}/${PROJECT_NAME}/.inventor     

   set -u
}

################################################################################
# function for validation of an entry with Yes/No Prompts
################################################################################
function custom_yesno_prompt()
{
    local QUESTION="$1"
    local MESSAGE="$2"
    local VALUETORETURN="$3"
    local YES="Yes"
    local NO="No"
 
    while true
    do
       echo $QUESTION
       echo -e "$MESSAGE: \c"
       read ANSWER

       OPTION=$(echo ${ANSWER}|tr '[:upper:]' '[:lower:]')

       case "${OPTION}" in
          [yY])
                #echo "You responded: ${OPTION}"
                VALUETORETURN=${YES}
                break
                ;;
          [nN]) 
                #echo "You responded: ${OPTION}"
                VALUETORETURN=${NO}
                break
                ;;
          *)
                echo "Invalid option '${OPTION}'. Please enter a correct value."
                ;;
        esac
    done

    #echo "${VALUETORETURN}"
    RESULT="${VALUETORETURN}"
}

################################################################################
# function for validation of an entry with arrays and choices
################################################################################
function custom_options_prompt()
{
    local QUESTION="$1"
    local SEEKANSWER=0

    #echo "${VALUETORETURN}"
    while true
    do
       echo $QUESTION
       for opt in "${OPTIONS[@]}"
       do
           echo "$opt"
       done
       read ANSWER

       #echo "You responded: ${ANSWER}"
       SEEKANSWER=$(echo "${CHOICES[@]}" | grep -i "${ANSWER}" | wc -w)
       #echo "seekanswer: ${SEEKANSWER}"

       if [[ "${SEEKANSWER}" -lt 1 ]]
       then
           echo "Invalid option '${ANSWER}'. Please enter a correct value."
       else
           break
       fi
    done

    #echo "${ANSWER}"
    RESULT="${ANSWER}"    
}

################################################################################
# function for validation of an string entry not being empty
################################################################################
function validate_string_not_empty()
{
    local QUESTION="$1"
    local MESSAGE="$2"

    #echo "${VALUETORETURN}"
    while true
    do
       if [[ -z "${MESSAGE}" ]]
       then
           echo -e "$QUESTION \c"
       else
           echo "$QUESTION"
           echo -e "$MESSAGE \c"           
       fi
       read ANSWER

       #echo "You responded: ${ANSWER}"
       if [[ -z "${ANSWER}" ]]
       then
           echo "Entered value cannot be empty. Please enter a correct value."
       else
           break
       fi
    done

    #echo "${ANSWER}"
    RESULT="${ANSWER}"
}

################################################################################
# function for validation of an password string entry not being empty
################################################################################
function validate_password_not_empty()
{
    local QUESTION="$1"

    echo "${VALUETORETURN}"
    while true
    do
       echo -e "$QUESTION \c"
       read -s ANSWER

       echo "You responded: ${ANSWER}"
       if [[ -z "${ANSWER}" ]]
       then
           echo "Entered value cannot be empty. Please enter a correct value."
       else
           break
       fi
    done

    echo "${ANSWER}"
    RESULT="${ANSWER}"
}

