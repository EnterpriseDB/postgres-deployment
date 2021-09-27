from . import DefaultAWSSpec
from . import SpecValidator

AuroraSpec = {
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'db.t3.medium', 'db.r5.xlarge', 'db.r5.2xlarge',
                'db.r5.4xlarge', 'db.r5.8xlarge'
            ],
            default='db.r5.2xlarge'
        )
    }
}

AWSRDSAuroraSpec = {**DefaultAWSSpec, **AuroraSpec}
