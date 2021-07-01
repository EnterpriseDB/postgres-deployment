from . import SpecValidator

GCloudSQLSpec = {
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
    'hammerdb_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'c2-standard-4', 'c2-standard-8', 'c2-standard-16'
            ],
            default='c2-standard-4'
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
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'db-custom-4-26624', 'db-custom-8-53248',
                'db-custom-16-106496', 'db-custom-32-212992'
            ],
            default='db-custom-4-26624'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['pd-standard', 'pd-ssd'],
                default='pd-ssd'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=50
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
                max=65536,
                default=100
            )
        }
    }
}

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
        'effective_cache_size': '9542041',
        'shared_buffers': '3145728',
        'max_wal_size': '204800',
    },
    'xl': {
        'effective_cache_size': '19084083',
        'shared_buffers': '3145728',
        'max_wal_size': '409600',
    },
}
