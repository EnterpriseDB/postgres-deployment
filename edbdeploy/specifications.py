import socket

from .spec import SpecValidator
from .spec.aws import AWSSpec
from .spec.aws_rds import AWSRDSSpec
from .spec.aws_rds_aurora import AWSRDSAuroraSpec
from .spec.azure import AzureSpec
from .spec.azure_db import AzureDBSpec
from .spec.gcloud import GCloudSpec
from .spec.gcloud_sql import GCloudSQLSpec
from .spec.baremetal import BaremetalSpec
from .spec.vmware import VMWareSpec
from .spec.virtualbox import VirtualBoxSpec
from .errors import SpecValidatorError


def merge(data, spec, defaults, path = []):
    """
    Recursive function for merging user data and cloud specifications.
    """
    # Initialize result to defaults values
    result = defaults

    # Walk through user data
    for key, value in data.items():
        path.append(key)

        if key not in defaults:
            raise SpecValidatorError(
                "%s: unexpected key %s" % ('.'.join(path[:-1]), key)
            )

        if isinstance(value, dict):
            # Merge recursively the value when it is a dictionary
            result[key] = merge(value, spec[key], defaults[key], path)

        elif isinstance(spec[key], SpecValidator):
            # Do user data validation if the corresponding value from the
            # specification is an instance of SpecValidator.
            if value is not None:
                result[key] = validate(value, spec[key], path)

        else:
            result[key] = value

        path.remove(key)
    return result

def validate(value, validator, path):
    """
    Value validation based on SpecValidator attributes
    """
    if validator.type == 'choice':
        if value not in validator.choices:
            raise SpecValidatorError(
                "%s: value '%s' not allowed, must be in list %s"
                % ('.'.join(path), value, validator.choices)
            )

    elif validator.type == 'integer':
        value = int(value)
        if value < validator.min or value > validator.max:
            raise SpecValidatorError(
                "%s: invalid value %s, must between %s and %s"
                % ('.'.join(path), value, validator.min, validator.max)
            )

    elif validator.type == 'ipv4':
        try:
            socket.inet_aton(value)
        except socket.error:
            raise SpecValidatorError(
                "%s: invalid IPv4 address format %s" % ('.'.join(path), value)
            )

    elif validator.type == 'string':
        value = str(value) if value is not None else None

    return value

def default(element):
    """
    Recursive function for building specification dictionary based on the
    default values.
    """
    result = {}

    for key, value in element.items():
        if isinstance(value, dict):
            result[key] = default(value)

        elif isinstance(value, SpecValidator):
            result[key] = value.default

        else:
            result[key] = value

    return result

def default_spec(cloud, reference_architecture=None):
    """
    Wrapper for the default function
    """
    if cloud == 'aws':
        return default(AWSSpec)
    elif cloud == 'aws-pot':
        # Use same specifications as aws
        return default(AWSSpec)
    elif cloud == 'aws-rds':
        return default(AWSRDSSpec)
    elif cloud == 'aws-rds-aurora':
        return default(AWSRDSAuroraSpec)
    elif cloud == 'azure':
        return default(AzureSpec)
    elif cloud == 'azure-pot':
        # Use same specifications as azure
        return default(AzureSpec)
    elif cloud == 'azure-db':
        return default(AzureDBSpec)
    elif cloud == 'gcloud':
        return default(GCloudSpec)
    elif cloud == 'gcloud-pot':
        # Use same specifications as gcloud
        return default(GCloudSpec)
    elif cloud == 'gcloud-sql':
        return default(GCloudSQLSpec)
    elif cloud == 'baremetal':
        return default(BaremetalSpec.get(reference_architecture))
    elif cloud == 'vmware':
        return default(VMWareSpec.get(reference_architecture))
    elif cloud == 'virtualbox':
        return default(VirtualBoxSpec.get(reference_architecture))
    else:
        return {}

def merge_user_spec(cloud, user_spec, reference_architecture=None):
    """
    Wrapper function for merging user specs. and default specs.
    """
    if cloud in ('aws', 'aws-pot'):
        cloud_spec = AWSSpec
    elif cloud == 'aws-rds':
        cloud_spec = AWSRDSSpec
    elif cloud == 'aws-rds-aurora':
        cloud_spec = AWSRDSAuroraSpec
    elif cloud in ('azure', 'azure-pot'):
        cloud_spec = AzureSpec
    elif cloud == 'azure-db':
        cloud_spec = AzureDBSpec
    elif cloud in ('gcloud', 'gcloud-pot'):
        cloud_spec = GCloudSpec
    elif cloud == 'gcloud-sql':
        cloud_spec = GCloudSQLSpec
    elif cloud == 'baremetal':
        cloud_spec = BaremetalSpec.get(reference_architecture)
    elif cloud == 'vmware':
        cloud_spec = VMWareSpec.get(reference_architecture)
    elif cloud == 'virtualbox':
        cloud_spec = VirtualBoxSpec.get(reference_architecture)

    defaults = default(cloud_spec)

    return merge(user_spec, cloud_spec, defaults)
