from . import DefaultGcloudSpec
from . import SpecValidator

GCSQLSpec = {
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

GCloudSQLSpec = {**DefaultGcloudSpec, **GCSQLSpec}