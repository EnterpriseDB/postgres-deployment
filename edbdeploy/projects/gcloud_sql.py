from ..action import ActionManager as AM
from ..project import Project
from ..spec.aws_rds import TPROCC_GUC


class GCloudSQLProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(GCloudSQLProject, self).__init__(
            'gcloud-sql', name, env, bin_path
        )

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)
        self._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._dbaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for GCloud SQL provisioning
        """

        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        guc = TPROCC_GUC

        self.terraform_vars.update({
            'gcloud_image': os['image'],
            'gcloud_region': env.gcloud_region,
            'gcloud_credentials': env.gcloud_credentials.name,
            'gcloud_project_id': env.gcloud_project_id,
            'guc_effective_cache_size': guc[env.shirt]['effective_cache_size'],
            'guc_max_wal_size': guc[env.shirt]['max_wal_size'],
            'guc_shared_buffers': guc[env.shirt]['shared_buffers'],
        })
        self.terraform_vars['postgres_server'].update({
            'instance_type': pg['instance_type'],
            'volume': pg['volume'],
        })

    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        pass

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        with AM("Checking instances availability in region %s"
                % self.terraform_vars['gcloud_region']):
            cloud_cli.cli.check_instances_availability(
                self.name,
                self.terraform_vars['gcloud_region'],
                # Total number of nodes
                (self.terraform_vars['postgres_server']['count']
                 + self.terraform_vars['pem_server']['count'])
            )
