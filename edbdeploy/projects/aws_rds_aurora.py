from .aws_rds import AWSRDSProject
from ..password import get_password
from ..spec.aws_rds import TPROCC_GUC


class AWSRDSAuroraProject(AWSRDSProject):
    def __init__(self, name, env, bin_path=None, using_edbterraform=True):
        super(AWSRDSProject, self).__init__(
            'aws-rds-aurora', name, env, bin_path, using_edbterraform
        )

    def hook_instances_availability(self, env):
        # Hook function called by Project.provision()
        # FIXME: really nothing to do in this case?
        pass

    def overrides(self, env):
        spec = self.terraform_vars[self.cloud_provider]
        spec['databases']['postgres'].update({
            'engine': 'aurora-postgresql',
            'zones': [self.terraform_vars['zones'][-1], self.terraform_vars['zones'][-2]],
            'count': 1,
        })
        spec['aurora'] = spec['databases'].copy()
        spec['databases'] = {}

    def database_settings(self, env):
        guc = TPROCC_GUC
        return [
            # checkpoint timeout not allowed
            #{'name': 'checkpoint_timeout', 'value': 900 },
            {'name': 'effective_cache_size', 'value': guc[env.shirt]['effective_cache_size']},
            {'name': 'max_connections', 'value': 300},
            # not configurable
            #{'name': 'max_wal_size', 'value': guc[env.shirt]['max_wal_size']},
            {'name': 'shared_buffers', 'value': guc[env.shirt]['shared_buffers']},
            {'name': 'work_mem', 'value': 65536},
        ]
