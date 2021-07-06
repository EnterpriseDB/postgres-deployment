from . import SpecValidator

AzureSpec = {
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
            'sku': SpecValidator(type='string', default="8.2"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        }
    },
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'Standard_A1_v2', 'Standard_A2_v2', 'Standard_A4_v2',
                'Standard_A8_v2', 'Standard_A2m_v2', 'Standard_A4m_v2',
                'Standard_A8m_v2', 'Standard_E4ds_v4', 'Standard_E8ds_v4',
                'Standard_E16ds_v4', 'Standard_E32ds_v4'
            ],
            default='Standard_A4_v2'
        ),
        'volume': {
            'storage_account_type': SpecValidator(
                type='choice',
                choices=['Premium_LRS', 'StandardSSD_LRS', 'Standard_LRS',
                         'UltraSSD_LRS'],
                default='Standard_LRS'
            )
        },
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=5,
                default=2
            ),
            'storage_account_type': SpecValidator(
                type='choice',
                choices=['Premium_LRS', 'StandardSSD_LRS', 'Standard_LRS',
                         'UltraSSD_LRS'],
                default='StandardSSD_LRS'
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
    'pooler_server': {
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
    'barman_server': {
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
        },
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=1,
                default=1
            ),
            'storage_account_type': SpecValidator(
                type='choice',
                choices=['Premium_LRS', 'StandardSSD_LRS', 'Standard_LRS',
                         'UltraSSD_LRS'],
                default='StandardSSD_LRS'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=300
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
        },
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=5,
                default=2
            ),
            'storage_account_type': SpecValidator(
                type='choice',
                choices=['Premium_LRS', 'StandardSSD_LRS', 'Standard_LRS',
                         'UltraSSD_LRS'],
                default='StandardSSD_LRS'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=100
            )
        }
    }
}
