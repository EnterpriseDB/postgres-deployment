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
  echo "    aws-config      [show|update]     PROJECT_NAME"
  echo "    azure-config    [show|update]     PROJECT_NAME"
  echo "    gcloud-config   [show|update]     PROJECT_NAME"
  echo "    aws-project     [list|switch]     PROJECT_NAME"
  echo "    azure-project   [list|switch]     PROJECT_NAME"
  echo "    gcloud-project  [list|switch]     PROJECT_NAME"

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
            "azure-config")
                shift; AZURE_CONFIG="${1}"
                AZURE_CONFIG="$(echo ${AWS_CONFIG}|tr '[:upper:]' '[:lower:]')"
                if [[ "${AZURE_CONFIG}" != "show" ]] && [[ "${AZURE_CONFIG}" != "update" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export AZURE_CONFIG PROJECT_NAME
                    break
                fi
                ;;
            "gcloud-config")
                shift; GCLOUD_CONFIG="${1}"
                GCLOUD_CONFIG="$(echo ${AWS_CONFIG}|tr '[:upper:]' '[:lower:]')"
                if [[ "${GCLOUD_CONFIG}" != "show" ]] && [[ "${GCLOUD_CONFIG}" != "update" ]]
                then
                    usage
                else
                    shift; PROJECT_NAME="${1}"
                    export GCLOUD_CONFIG PROJECT_NAME
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
            "azure-project")
                shift; AZURE_PROJECT="${1}"
                AZURE_PROJECT="$(echo ${AZURE_PROJECT}|tr '[:upper:]' '[:lower:]')"
                if [[ "${AZURE_PROJECT}" != "list" ]] && [[ "${AZURE_PROJECT}" != "switch" ]]
                then
                    usage
                else
                    if [[ "${AZURE_PROJECT}" = "list" ]]
                    then
                        shift; PROJECT_NAME=" "                    
                    else
                        shift; PROJECT_NAME="${1}"
                    fi
                    export AZURE_PROJECT PROJECT_NAME
                    break
                fi
                ;;
            "gcloud-project")
                shift; GCLOUD_PROJECT="${1}"
                GCLOUD_PROJECT="$(echo ${GCLOUD_PROJECT}|tr '[:upper:]' '[:lower:]')"
                if [[ "${GCLOUD_PROJECT}" != "list" ]] && [[ "${GCLOUD_PROJECT}" != "switch" ]]
                then
                    usage
                else
                    if [[ "${GCLOUD_PROJECT}" = "list" ]]
                    then
                        shift; PROJECT_NAME=" "                    
                    else
                        shift; PROJECT_NAME="${1}"
                    fi
                    export GCLOUD_PROJECT PROJECT_NAME
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
