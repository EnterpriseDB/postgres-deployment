from . import DefaultGcloudSpec
from . import SpecValidator

GCVMSpec = {
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'e2-standard-2', 'e2-standard-4', 'e2-standard-8',
                'e2-standard-16', 'e2-standard-32', 'e2-highmem-2',
                'e2-highmem-4', 'e2-highmem-8', 'e2-highmem-16',
                'n2-highmem-4', 'n2-highmem-8', 'n2-highmem-16',
                'n2-highmem-32'
            ],
            default='e2-standard-4'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-standard'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=50
            )
        },
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=5,
                default=2
            ),
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-ssd'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=65536,
                default=100
            )
        }
    },
    'bdr_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'e2-standard-2', 'e2-standard-4', 'e2-standard-8',
                'e2-standard-16', 'e2-standard-32', 'e2-highmem-2',
                'e2-highmem-4', 'e2-highmem-8', 'e2-highmem-16',
                'n2-highmem-4', 'n2-highmem-8', 'n2-highmem-16',
                'n2-highmem-32'
            ],
            default='e2-standard-4'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-standard'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=50
            )
        },
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=5,
                default=2
            ),
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-ssd'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=65536,
                default=100
            )
        }
    },
    'bdr_witness_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'e2-standard-2', 'e2-standard-4', 'e2-standard-8',
                'e2-standard-16', 'e2-standard-32', 'e2-highmem-2',
                'e2-highmem-4', 'e2-highmem-8', 'e2-highmem-16'
            ],
            default='e2-standard-2'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-standard'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=65536,
                default=50
            )
        }
    },
    'pooler_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'e2-standard-2', 'e2-standard-4', 'e2-standard-8',
                'e2-standard-16', 'e2-standard-32', 'e2-highmem-2',
                'e2-highmem-4', 'e2-highmem-8', 'e2-highmem-16'
            ],
            default='e2-standard-2'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-standard'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=65536,
                default=50
            )
        }
    },
    'barman_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'e2-standard-2', 'e2-standard-4', 'e2-standard-8',
                'e2-standard-16', 'e2-standard-32', 'e2-highmem-2',
                'e2-highmem-4', 'e2-highmem-8', 'e2-highmem-16'
            ],
            default='e2-standard-2'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-standard'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=65536,
                default=50
            )
        },
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=1,
                default=1
            ),
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-ssd'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=65536,
                default=300
            )
        }
    }
}

GCloudSpec = {**DefaultGcloudSpec, **GCVMSpec}