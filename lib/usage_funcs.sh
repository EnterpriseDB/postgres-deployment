#! /bin/bash
################################################################################
# Title           : usage script to capture the users argument and
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
# source common lib
################################################################################
DIRECTORY=$(dirname $0)
if [[ "${DIRECTORY}" = "." ]]
then
   DIRECTORY="${PWD}"
fi
#source ${DIRECTORY}/lib/common_funcs.sh

################################################################################
# function to show the usage
################################################################################
function usage()
{
  echo "${BASENAME} [<cloud>-server|<cloud>-postgres] [OPTION]..."
  echo ""
  echo "EDB deployment script for aws, azure and gcp"
  echo ""
  echo "Subcommands:"
  echo "    aws-server      [create|destroy]  PROJECT_NAME"
  echo "    aws-postgres    install           PROJECT_NAME"
  echo "    aws-config      [show|update]     PROJECT_NAME"
  echo "    aws-project     [list|switch]     PROJECT_NAME"

  echo ""
  echo "Other Options:"
  echo "    -h, --help Display help and exit"
  exit 1
}

################################################################################
# function to verify the arguments
################################################################################
function verify_arguments()
{
    set +u
    local F_ARGUMENTS="$1"
    local F_LENGTH=$(echo ${F_ARGUMENTS}|wc -w)

    if [[ ${F_LENGTH} -lt 1 ]]
    then
        usage
    fi

    while ((${F_LENGTH})); do
        case $F_ARGUMENTS in
            "-h"|"--help")
                usage
                ;;
            "aws-server")
                shift; AWS_SERVER="${1}"
                AWS_SERVER="$(echo ${AWS_SERVER}|tr '[:upper:]' '[:lower:]')"
                if [[ "${AWS_SERVER}" != "create" ]] && [[ "${AWS_SERVER}" != "destroy" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export AWS_SERVER PROJECT_NAME
                    break
                fi
                ;;
            "aws-postgres")
                shift; AWS_POSTGRES_INSTALL="${1}"
                if [[ "${AWS_POSTGRES_INSTALL}" != "install" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export POSTGRES_INSTALL PROJECT_NAME
                    break
                fi
                ;;
            "aws-config")
                shift; AWS_CONFIG="${1}"
                AWS_CONFIG="$(echo ${AWS_CONFIG}|tr '[:upper:]' '[:lower:]')"
                if [[ "${AWS_CONFIG}" != "show" ]] && [[ "${AWS_CONFIG}" != "update" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export AWS_CONFIG PROJECT_NAME
                    break
                fi
                ;;
            "aws-project")
                shift; AWS_PROJECT="${1}"
                AWS_PROJECT="$(echo ${AWS_PROJECT}|tr '[:upper:]' '[:lower:]')"
                if [[ "${AWS_PROJECT}" != "list" ]] && [[ "${AWS_PROJECT}" != "switch" ]]
                then
                    usage
                else
                    if [[ "${AWS_PROJECT}" = "list" ]]
                    then
                        shift; PROJECT_NAME=" "                    
                    else
                        shift; PROJECT_NAME="${1}"
                    fi
                    export AWS_PROJECT PROJECT_NAME
                    break
                fi
                ;;
            *)
                usage
                ;;
        esac
    done
    set -u
}
