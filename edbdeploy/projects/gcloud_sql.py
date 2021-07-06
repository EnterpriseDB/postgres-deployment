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
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        hammerdb = env.cloud_spec['hammerdb_server']
        guc = TPROCC_GUC

        self.terraform_vars = {
            'gcloud_image': os['image'],
            'gcloud_region': env.gcloud_region,
            'gcloud_credentials': env.gcloud_credentials.name,
            'gcloud_project_id': env.gcloud_project_id,
            'guc_effective_cache_size': guc[env.shirt]['effective_cache_size'],
            'guc_max_wal_size': guc[env.shirt]['max_wal_size'],
            'guc_shared_buffers': guc[env.shirt]['shared_buffers'],
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
            'pg_version': env.postgres_version,
            'postgres_server': {
                'count': ra['pg_count'],
                'instance_type': pg['instance_type'],
                'volume': pg['volume'],
            },
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

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
