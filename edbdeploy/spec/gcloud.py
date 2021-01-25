from . import SpecValidator

GCloudSpec = {
    'available_os': {
        'CentOS7': {
            'image': SpecValidator(type='string', default="centos-7"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'CentOS8': {
            'image': SpecValidator(type='string', default="centos-8"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'RedHat7': {
            'image': SpecValidator(type='string', default="rhel-7"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'RedHat8': {
            'image': SpecValidator(type='string', default="rhel-8"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        }
    },
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'e2-standard-2', 'e2-standard-4', 'e2-standard-8',
                'e2-standard-16', 'e2-standard-32', 'e2-highmem-2',
                'e2-highmem-4', 'e2-highmem-8', 'e2-highmem-16'
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
                max=16000,
                default=100
            )
        }
    },
    'pem_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'e2-standard-2', 'e2-standard-4', 'e2-standard-8',
                'e2-standard-16', 'e2-standard-32', 'e2-highmem-2',
                'e2-highmem-4', 'e2-highmem-8', 'e2-highmem-16'
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
                default=100
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
                max=16000,
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
                max=16000,
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
                max=16000,
                default=300
            )
        }
    }
}
