from . import SpecValidator

EDBRA1Spec = {
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
    },
    'dbt2_driver': {
        'count': SpecValidator(
            type='integer',
            min=0,
            max=64,
            default=0
        ),
    },
    'available_os': {
        'RockyLinux8': {
            'image': SpecValidator(
                type='string',
                default='generic/rocky8',
            ),
        },
    },
    'ipv4': SpecValidator(type='ipv4', default='192.168.56.101'),
    'ssh_user': SpecValidator(type='string', default=None),
    'pg_data': SpecValidator(type='string', default=None),
    'pg_wal': SpecValidator(type='string', default=None),
    'postgres_server_1': {
        'name': SpecValidator(type='string', default='primary1'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
    'pem_server_1': {
        'name': SpecValidator(type='string', default='pem1'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
    'backup_server_1': {
        'name': SpecValidator(type='string', default='barman1'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
}

EDBRA2Spec = {
    **EDBRA1Spec,
    'postgres_server_2': {
        'name': SpecValidator(type='string', default='primary2'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
    'postgres_server_3': {
        'name': SpecValidator(type='string', default='primary3'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
}

EDBRA3Spec = {
    **EDBRA2Spec,
    'pooler_server_1': {
        'name': SpecValidator(type='string', default='pooler1'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
    'pooler_server_2': {
        'name': SpecValidator(type='string', default='pooler2'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
    'pooler_server_3': {
        'name': SpecValidator(type='string', default='pooler3'),
        'public_ip': SpecValidator(type='ipv4', default=None),
        'private_ip': SpecValidator(type='ipv4', default=None),
    },
}

VirtualBoxSpec = {
    'EDB-RA-1': EDBRA1Spec,
    'EDB-RA-2': EDBRA2Spec,
    'EDB-RA-3': EDBRA3Spec,
}
