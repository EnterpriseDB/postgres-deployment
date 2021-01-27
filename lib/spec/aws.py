from . import SpecValidator

AWSSpec = {
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
        'CentOS8': {
            'image': SpecValidator(
                type='string',
                default="CentOS 8*"
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
        }
    },
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge',
                'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
                'c5.metal'
            ],
            default='c5.2xlarge'
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
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=5,
                default=2
            ),
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
            ),
            'encrypted': SpecValidator(
                type='choice',
                choices=[True, False],
                default=False
            )
        }
    },
    'pem_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge',
                'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
                'c5.metal'
            ],
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
    },
    'pooler_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge',
                'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
                'c5.metal'
            ],
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
                default=30
            ),
            'iops': SpecValidator(
                type='integer',
                min=100,
                max=64000,
                default=250
            )
        }
    },
    'barman_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge',
                'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
                'c5.metal'
            ],
            default='c5.2xlarge'
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
        'additional_volumes': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=1,
                default=1
            ),
            'type': SpecValidator(
                type='choice',
                choices=['io1', 'io2', 'gp2', 'gp3', 'st1', 'sc1'],
                default='gp2'
            ),
            'size': SpecValidator(
                type='integer',
                min=10,
                max=16000,
                default=300
            ),
            'iops': SpecValidator(
                type='integer',
                min=100,
                max=64000,
                default=250
            ),
            'encrypted': SpecValidator(
                type='choice',
                choices=[True, False],
                default=False
            )
        }
    }
}
