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
#source ${DIRECTORY}/lib/common_funcs.sh

################################################################################
# function to show the usage
################################################################################
function usage()
{
  echo "${BASENAME} [aws-server|postgres] [OPTION]..."
  echo ""
  echo "EDB deployment script for aws"
  echo ""
  echo "Subcommands:"
  echo "    aws-server     [create|destroy]  PROJECT_NAME"
  echo "    postgres       install           PROJECT_NAME"
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
            "postgres")
                shift; POSTGRES_INSTALL="${1}"
                if [[ "${POSTGRES_INSTALL}" != "install" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export POSTGRES_INSTALL PROJECT_NAME
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
