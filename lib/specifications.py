from .spec import SpecValidator
from .spec.aws import AWSSpec
from .spec.azure import AzureSpec
from .spec.gcloud import GCloudSpec

class SpecValidatorError(Exception):
    pass

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

    elif validator.type == 'string':
        value = str(value)

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

def default_spec(cloud):
    """
    Wrapper for the default function
    """
    if cloud == 'aws':
        return default(AWSSpec)
    elif cloud == 'azure':
        return default(AzureSpec)
    elif cloud == 'gcloud':
        return default(GCloudSpec)
    else:
        return {}

def merge_user_spec(cloud, user_spec):
    """
    Wrapper function for merging user specs. and default specs.
    """
    if cloud == 'aws':
        cloud_spec = AWSSpec
    elif cloud == 'azure':
        cloud_spec = AzureSpec
    elif cloud == 'gcloud':
        cloud_spec = GCloudSpec

    defaults = default(cloud_spec)

    return merge(user_spec, cloud_spec, defaults)
