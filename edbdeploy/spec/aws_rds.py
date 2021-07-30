from . import DefaultAWSSpec
from . import SpecValidator

RDSSpec = {
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'db.t3.micro', 'db.r5.xlarge', 'db.r5.2xlarge',
                'db.r5.4xlarge', 'db.r5.8xlarge'
            ],
            default='db.r5.2xlarge'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['io1'],
                default='io1'
            ),
            'size': SpecValidator(
                type='integer',
                min=100,
                max=16384,
                default=1000
            ),
            'iops': SpecValidator(
                type='integer',
                min=1000,
                max=80000,
                default=10000
            )
        }
    }
}

AWSRDSSpec = {**DefaultAWSSpec, **RDSSpec}

TPROCC_GUC = {
    'small': {
        'effective_cache_size': '524288',
        'shared_buffers': '3145728',
        'max_wal_size': '51200',
    },
    'medium': {
        'effective_cache_size': '4718592',
        'shared_buffers': '3145728',
        'max_wal_size': '102400',
    },
    'large': {
        'effective_cache_size': '13107200',
        'shared_buffers': '3145728',
        'max_wal_size': '204800',
    },
    'xl': {
        'effective_cache_size': '29884416',
        'shared_buffers': '3145728',
        'max_wal_size': '409600',
    },
}
