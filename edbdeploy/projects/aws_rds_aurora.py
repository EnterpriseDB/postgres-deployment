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
        """
        Build Terraform variable for AWS RDS Aurora provisioning
        """

        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        ra = self.reference_architecture[env.reference_architecture]
        os = env.cloud_spec['available_os'][env.operating_system]

        self.terraform_vars.update({
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os['image'],
            'aws_region': env.aws_region,
            'pg_password': get_password(self.project_path, 'postgres'),
            'pg_version': env.postgres_version,
        })
