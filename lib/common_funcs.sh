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
CONFIG_DIR=~/.edb
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

