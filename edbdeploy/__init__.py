__version__ = "3.13.0"
# Version number of the Ansible collection we want to use
__edb_ansible_version__ = "3.16.0"

def to_num(version):
    """
    Convert version number from 3 digits tuple to 1 integer.
    (1, 2, 3) -> 100020003
    """
    v = ''
    for n in version:
        v += '{0:04d}'.format(int(n))
    return int(v)


def to_str(version):
    """
    Convert version from 3 digits tuple to string.
    (1, 2, 3) -> '1.2.3'
    """
    return '.'.join(map(str, version))


def check_version(version, min_version, max_version):
    """
    Software version checking function ensuring that the given version is part
    of the interval formed by [min, max].
    version, min_version and max_version are 3 digits tuples/lists.
    """
    return (to_num(min_version) <= to_num(version) <= to_num(max_version))
