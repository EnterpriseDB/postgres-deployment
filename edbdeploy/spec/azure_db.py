from . import DefaultAzureSpec
from . import SpecValidator

SingleServerSpec = {
    'postgres_server': {
        'sku': SpecValidator(
            type='choice',
            choices=['B_Gen4_1', 'B_Gen4_2', 'B_Gen5_1', 'B_Gen5_2',
                     'GP_Gen4_2', 'GP_Gen4_4', 'GP_Gen4_8', 'GP_Gen4_16',
                     'GP_Gen4_32', 'GP_Gen5_2', 'GP_Gen5_4', 'GP_Gen5_8',
                     'GP_Gen5_16', 'GP_Gen5_32', 'GP_Gen5_64', 'MO_Gen5_2',
                     'MO_Gen5_4', 'MO_Gen5_8', 'MO_Gen5_16', 'MO_Gen5_32'
            ],
            default='B_Gen5_2'
        ),
        'size': SpecValidator(
            type='integer',
            min=5120,
            max=16777216,
            default=5120
        )
    }
}

TPROCC_GUC = {
    'small': {
        'effective_cache_size': '524288',
        'max_wal_size': '51200',
    },
    'medium': {
        'effective_cache_size': '4718592',
        'max_wal_size': '102400',
    },
    'large': {
        'effective_cache_size': '13107200',
        'max_wal_size': '204800',
    },
    'xl': {
        'effective_cache_size': '29884416',
        'max_wal_size': '409600',
    },
}

AzureDBSpec = {**DefaultAzureSpec, **SingleServerSpec}