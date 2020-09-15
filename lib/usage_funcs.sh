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
  echo "    azure-server    [create|destroy]  PROJECT_NAME"
  echo "    gcloud-server   [create|destroy]  PROJECT_NAME"
  echo "    aws-postgres    install           PROJECT_NAME"
  echo "    azure-postgres  install           PROJECT_NAME"
  echo "    gcloud-postgres install           PROJECT_NAME"      
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
            "azure-server")
                shift; AZURE_SERVER="${1}"
                AZURE_SERVER="$(echo ${AZURE_SERVER}|tr '[:upper:]' '[:lower:]')"
                if [[ "${AZURE_SERVER}" != "create" ]] && [[ "${AZURE_SERVER}" != "destroy" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export AZURE_SERVER PROJECT_NAME
                    break
                fi
                ;;
            "gcloud-server")
                shift; GCLOUD_SERVER="${1}"
                GCLOUD_SERVER="$(echo ${GCLOUD_SERVER}|tr '[:upper:]' '[:lower:]')"
                if [[ "${GCLOUD_SERVER}" != "create" ]] && [[ "${GCLOUD_SERVER}" != "destroy" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export GCLOUD_SERVER PROJECT_NAME
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
            "azure-postgres")
                shift; AZURE_POSTGRES_INSTALL="${1}"
                if [[ "${AZURE_POSTGRES_INSTALL}" != "install" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export POSTGRES_INSTALL PROJECT_NAME
                    break
                fi
                ;;
            "gcloud-postgres")
                shift; GCLOUD_POSTGRES_INSTALL="${1}"
                if [[ "${GCLOUD_POSTGRES_INSTALL}" != "install" ]]
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
