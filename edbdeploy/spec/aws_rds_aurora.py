from . import SpecValidator

# These are instance types to make available to all architectures.
global_instance_choices = ['t3.nano', 't3a.nano', 't2.nano']

AWSRDSAuroraSpec = {
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
    'hammerdb_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'm5n.xlarge', 'm5n.2xlarge', 'm5n.4xlarge'
            ] + global_instance_choices,
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
    'postgres_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'db.t3.medium', 'db.r5.xlarge', 'db.r5.2xlarge',
                'db.r5.4xlarge', 'db.r5.8xlarge'
            ],
            default='db.r5.2xlarge'
        )
    },
    'pem_server': {
        'instance_type': SpecValidator(
            type='choice',
            choices=[
                'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge',
                'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
                'c5.metal'
            ] + global_instance_choices,
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
