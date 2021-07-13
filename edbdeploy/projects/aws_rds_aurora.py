from .aws_rds import AWSRDSProject
from ..password import get_password


class AWSRDSAuroraProject(AWSRDSProject):
    def __init__(self, name, env, bin_path=None):
        super(AWSRDSProject, self).__init__(
            'aws-rds-aurora', name, env, bin_path
        )

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        # FIXME: really nothing to do in this case?
        pass

    def _build_terraform_vars(self, env):
        # Overload AWSRDSProject._build_terraform_vars()
        """
        Build Terraform variable for AWS RDS Aurora provisioning
        """
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        hammerdb = env.cloud_spec['hammerdb_server']

        self.terraform_vars = {
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os['image'],
            'aws_region': env.aws_region,
            'cluster_name': self.name,
            'hammerdb': ra['hammerdb'],
            'hammerdb_server': {
                'count': 1 if ra['hammerdb_server'] else 0,
                'instance_type': hammerdb['instance_type'],
                'volume': hammerdb['volume'],
            },
            'pem_server': {
                'count': 1 if ra['pem_server'] else 0,
                'instance_type': pem['instance_type'],
                'volume': pem['volume'],
            },
            'pg_password': get_password(self.project_path, 'postgres'),
            'pg_version': env.postgres_version,
            'postgres_server': {
                'count': ra['pg_count'],
                'instance_type': pg['instance_type'],
            },
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }
