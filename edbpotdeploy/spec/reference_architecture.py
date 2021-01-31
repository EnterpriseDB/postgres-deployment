ReferenceArchitectureSpec = {
    'EDB-RA-1': {
        'pg_count': 1,
        'pem_server': True,
        'barman': True,
        'barman_server': True,
        'pooler_count': 0,
        'pooler_type': None,
        'pooler_local': False,
        'efm': False,
        'replication_type': None
    },
    'EDB-RA-2': {
        'pg_count': 3,
        'pem_server': True,
        'barman': False,
        'barman_server': False,
        'pooler_count': 0,
        'pooler_type': None,
        'pooler_local': False,
        'efm': True,
        'replication_type': "asynchronous"
    },
    'EDB-RA-3': {
        'pg_count': 3,
        'pem_server': True,
        'barman': True,
        'barman_server': True,
        'pooler_count': 3,
        'pooler_type': "pgpool2",
        'pooler_local': False,
        'efm': True,
        'replication_type': "synchronous"
    }
}
