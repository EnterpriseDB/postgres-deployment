from . import SpecValidator

AzureDBSpec = {
    'available_os': {
        'CentOS7': {
            'publisher': SpecValidator(type='string', default="OpenLogic"),
            'offer': SpecValidator(type='string', default="CentOS"),
            'sku': SpecValidator(type='string', default="7.7"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'CentOS8': {
            'publisher': SpecValidator(type='string', default="OpenLogic"),
            'offer': SpecValidator(type='string', default="CentOS"),
            'sku': SpecValidator(type='string', default="8_1"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'RedHat7': {
            'publisher': SpecValidator(type='string', default="RedHat"),
            'offer': SpecValidator(type='string', default="RHEL"),
            'sku': SpecValidator(type='string', default="7.8"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'RedHat8': {
            'publisher': SpecValidator(type='string', default="RedHat"),
            'offer': SpecValidator(type='string', default="RHEL"),
            'sku': SpecValidator(type='string', default="8_2"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        }
    },
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
    },
    'pem_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'Standard_A1_v2', 'Standard_A2_v2', 'Standard_A4_v2',
                'Standard_A8_v2', 'Standard_A2m_v2', 'Standard_A4m_v2',
                'Standard_A8m_v2'
            ],
            default='Standard_A2_v2'
        ),
        'volume': {
            'storage_account_type': SpecValidator(
                type='choice',
                choices=['Premium_LRS', 'StandardSSD_LRS', 'Standard_LRS',
                         'UltraSSD_LRS'],
                default='Standard_LRS'
            )
        }
    },
    'hammerdb_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'Standard_D4ds_v4', 'Standard_D8ds_v4'
            ],
            default='Standard_D4ds_v4'
        ),
        'volume': {
            'storage_account_type': SpecValidator(
                type='choice',
                choices=['Premium_LRS', 'StandardSSD_LRS', 'Standard_LRS',
                         'UltraSSD_LRS'],
                default='Standard_LRS'
            )
        }
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
