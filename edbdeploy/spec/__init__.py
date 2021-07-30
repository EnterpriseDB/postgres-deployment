# These are instance types to make available to all AWS systems.
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
            default=1
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
            default=1
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
