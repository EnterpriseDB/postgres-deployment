# These are instance types to make available to all AWS EC2 systems, except the .
# PostgreSQL server, until the auto tuning playbook can tune for systems that
# small.
AWSGlobalInstanceChoices = [
        't2.nano', 't2.micro',
        't3.nano', 't3.micro',
        't3a.nano', 't3a.micro',
]


class SpecValidator:
    def __init__(self, type=None, default=None, choices=[], min=None,
                 max=None):
        self.type = type
        self.default = default
        self.choices = choices
        self.min = min
        self.max = max


DefaultAWSSpec = {
    'available_os': {
        'CentOS7': {
            'image': SpecValidator(
                type='string',
                default="CentOS Linux 7 x86_64 HVM EBS*"
            ),
            'ssh_user': SpecValidator(
                type='choice',
                choices=['centos'],
                default='centos'
            )
        },
        'RedHat7': {
            'image': SpecValidator(
                type='string',
                default="RHEL-7.8-x86_64*"
            ),
            'ssh_user': SpecValidator(
                type='choice',
                choices=['ec2-user'],
                default='ec2-user'
            )
        },
        'RedHat8': {
            'image': SpecValidator(
                type='string',
                default="RHEL-8.2-x86_64*"
            ),
            'ssh_user': SpecValidator(
                type='choice',
                choices=['ec2-user'],
                default='ec2-user'
            )
        },
        'RockyLinux8': {
            'image': SpecValidator(
                type='string',
                default="Rocky-8-ec2-8.5-20211114.2.x86_64"
            ),
            'ssh_user': SpecValidator(
                type='choice',
                choices=['rocky'],
                default='rocky'
            )
        }

    },
    'dbt2': SpecValidator(
        type='choice',
        choices=[True, False],
        default=False
    ),
    'dbt2_client': {
        'count': SpecValidator(
            type='integer',
            min=0,
            max=64,
            default=0
        ),
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'm5n.xlarge', 'm5n.2xlarge', 'm5n.4xlarge'
            ] + AWSGlobalInstanceChoices,
            default='m5n.xlarge'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['io1', 'io2', 'gp2', 'gp3', 'st1', 'sc1'],
                default='gp2'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=50
            ),
            'iops': SpecValidator(
                type='integer',
                min=100,
                max=64000,
                default=250
            )
        },
    },
    'dbt2_driver': {
        'count': SpecValidator(
            type='integer',
            min=0,
            max=64,
            default=0
        ),
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'm5n.xlarge', 'm5n.2xlarge', 'm5n.4xlarge'
            ] + AWSGlobalInstanceChoices,
            default='m5n.xlarge'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['io1', 'io2', 'gp2', 'gp3', 'st1', 'sc1'],
                default='gp2'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=50
            ),
            'iops': SpecValidator(
                type='integer',
                min=100,
                max=64000,
                default=250
            )
        },
    },
    'hammerdb_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'm5n.xlarge', 'm5n.2xlarge', 'm5n.4xlarge'
            ] + AWSGlobalInstanceChoices,
            default='m5n.xlarge'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['io1', 'io2', 'gp2', 'gp3', 'st1', 'sc1'],
                default='gp2'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=50
            ),
            'iops': SpecValidator(
                type='integer',
                min=100,
                max=64000,
                default=250
            )
        },
    },
    'pem_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge',
                'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
                'c5.metal'
            ] + AWSGlobalInstanceChoices,
            default='c5.xlarge'
        ),
        'volume': {
            'type': SpecValidator(
                type='choice',
                choices=['io1', 'io2', 'gp2', 'gp3', 'st1', 'sc1'],
                default='gp2'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=100
            ),
            'iops': SpecValidator(
                type='integer',
                min=100,
                max=64000,
                default=250
            )
        }
    }
}

DefaultAzureSpec = {
    'available_os': {
        'CentOS7': {
            'publisher': SpecValidator(type='string', default="OpenLogic"),
            'offer': SpecValidator(type='string', default="CentOS"),
            'sku': SpecValidator(type='string', default="7.7"),
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
        },
        'RockyLinux8': {
            'publisher': SpecValidator(type='string', default="Perforce"),
            'offer': SpecValidator(type='string', default="rockylinux8"),
            'sku': SpecValidator(type='string', default="8"),
            'ssh_user': SpecValidator(type='string', default='rocky')
        }
    },
    'dbt2': SpecValidator(
        type='choice',
        choices=[True, False],
        default=False
    ),
    'dbt2_driver': {
        'count': SpecValidator(
            type='integer',
            min=0,
            max=64,
            default=0
        ),
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
    'dbt2_client': {
        'count': SpecValidator(
            type='integer',
            min=0,
            max=64,
            default=0
        ),
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

DefaultGcloudSpec = {
    'available_os': {
        'CentOS7': {
            'image': SpecValidator(type='string', default="centos-7"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'RedHat7': {
            'image': SpecValidator(type='string', default="rhel-7"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'RedHat8': {
            'image': SpecValidator(type='string', default="rhel-8"),
            'ssh_user': SpecValidator(type='string', default='edbadm')
        },
        'RockyLinux8': {
            'image': SpecValidator(type='string', default="rocky-linux-8"),
            'ssh_user': SpecValidator(type='string', default='rocky')
        }
    },
    'dbt2': SpecValidator(
        type='choice',
        choices=[True, False],
        default=False
    ),
    'dbt2_client': {
        'count': SpecValidator(
            type='integer',
            min=0,
            max=64,
            default=0
        ),
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
        }
    },
    'dbt2_driver': {
        'count': SpecValidator(
            type='integer',
            min=0,
            max=64,
            default=0
        ),
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
