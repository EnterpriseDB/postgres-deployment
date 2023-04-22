from . import DefaultAzureSpec
from . import SpecValidator

FlexibleServerSpec = {
    'postgres_server': {
        'sku': SpecValidator(
            type='choice',
            choices=['B_Standard_B1ms', 'B_Standard_B2s', 'B_Standard_B2ms', 'B_Standard_B4ms',
                     'GP_Standard_D2s_v3', 'GP_Standard_D4s_v3', 'GP_Standard_D8s_v3', 'GP_Standard_D16s_v3',
                     'GP_Standard_D32s_v3', 'GP_Standard_D2ds_v4', 'GP_Standard_D4ds_v4', 'GP_Standard_D8ds_v4',
                     'GP_Standard_D16ds_v4', 'GP_Standard_D32ds_v4', 'GP_Standard_D64ds_v4', 'MO_Standard_E2s_v3',
                     'MO_Standard_E4s_v3', 'MO_Standard_E8s_v3', 'MO_Standard_E16s_v3', 'MO_Standard_E32s_v3'
            ],
            default='B_Standard_B1ms'
        ),
        'size': SpecValidator(
            type='integer',
            min=32,
            max=16777216,
            default=32
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

AzureDBSpec = {**DefaultAzureSpec, **FlexibleServerSpec}