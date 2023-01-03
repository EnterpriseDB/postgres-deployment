from . import SpecValidator

BaremetalSpec = {
    'EDB-RA-1': {
        'ssh_user': SpecValidator(type='string', default=None),
        'pg_data': SpecValidator(type='string', default=None),
        'pg_wal': SpecValidator(type='string', default=None),
        'postgres_server_1': {
            'name': SpecValidator(type='string', default='pg1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'pem_server_1': {
            'name': SpecValidator(type='string', default='pem1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'backup_server_1': {
            'name': SpecValidator(type='string', default='backup1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'dbt2_client_0': {
            'name': SpecValidator(type='string', default='dbt2client'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'dbt2_driver_0': {
            'name': SpecValidator(type='string', default='dbt2driver'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
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
        },
        'dbt2_driver': {
            'count': SpecValidator(
                type='integer',
                min=0,
                max=64,
                default=0
            ),
        },
    },
    'EDB-RA-2': {
        'ssh_user': SpecValidator(type='string', default=None),
        'pg_data': SpecValidator(type='string', default=None),
        'pg_wal': SpecValidator(type='string', default=None),
        'postgres_server_1': {
            'name': SpecValidator(type='string', default='pg1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'postgres_server_2': {
            'name': SpecValidator(type='string', default='pg2'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'postgres_server_3': {
            'name': SpecValidator(type='string', default='pg3'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'pem_server_1': {
            'name': SpecValidator(type='string', default='pem1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'backup_server_1': {
            'name': SpecValidator(type='string', default='backup1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        }
    },
    'EDB-RA-3': {
        'ssh_user': SpecValidator(type='string', default=None),
        'pg_data': SpecValidator(type='string', default=None),
        'pg_wal': SpecValidator(type='string', default=None),
        'postgres_server_1': {
            'name': SpecValidator(type='string', default='pg1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'postgres_server_2': {
            'name': SpecValidator(type='string', default='pg2'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        },
        'postgres_server_3': {
            'name': SpecValidator(type='string', default='pg3'),
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
            'name': SpecValidator(type='string', default='backup1'),
            'public_ip': SpecValidator(type='ipv4', default=None),
            'private_ip': SpecValidator(type='ipv4', default=None),
        }
    }
}
