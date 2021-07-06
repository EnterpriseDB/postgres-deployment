from . import SpecValidator

VMWareSpec = {
    'EDB-RA-1': {
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
        }
    },
    'EDB-RA-2': {
        'ssh_user': SpecValidator(type='string', default=None),
        'pg_data': SpecValidator(type='string', default=None),
        'pg_wal': SpecValidator(type='string', default=None),
        'postgres_server_1': {
            'name': SpecValidator(type='string', default='primary1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
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
        'pem_server_1': {
            'name': SpecValidator(type='string', default='pem1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'backup_server_1': {
            'name': SpecValidator(type='string', default='barman1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        }
    },
    'EDB-RA-3': {
        'ssh_user': SpecValidator(type='string', default=None),
        'pg_data': SpecValidator(type='string', default=None),
        'pg_wal': SpecValidator(type='string', default=None),
        'postgres_server_1': {
            'name': SpecValidator(type='string', default='primary1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
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
        'pem_server_1': {
            'name': SpecValidator(type='string', default='pem1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'backup_server_1': {
            'name': SpecValidator(type='string', default='barman1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        }
    }
}
