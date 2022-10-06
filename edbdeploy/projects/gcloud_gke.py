import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..project import Project
from ..render import build_inventory_yml


class GCloudGKEProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(GCloudGKEProject, self).__init__('gcloud-gke', name, env, bin_path)
        # Use Gcloud terraform code
        self.terraform_path = os.path.join(self.terraform_share_path, 'gcloud-gke')
        # kubernetes only attributes
        self.ansible_kubernetes_role = os.path.join(self.ansible_share_path, 'kubernetes_roles')        

    def configure(self, env):
        self.gcloud_gke_configure(env)
        
    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)
        #self._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        #self._copy_ansible_playbook()
        # Check Cloud Instance type and Image availability.
        #self._check_instance_image(env)

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        region = self.terraform_vars['gcloud_region']
        with AM("Checking instances availability in region %s" % region):
            cloud_cli.cli.check_instances_availability(
                self.name,
                region,
                # Total number of nodes
                (self.terraform_vars['postgres_server']['count']
                 + self.terraform_vars['barman_server']['count']
                 + self.terraform_vars['pem_server']['count']
                 + self.terraform_vars['pooler_server']['count'])
            )

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._iaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for GCloud provisioning
        """
        self.terraform_vars = {
            'cnpType': env.cnpType,            
            'gcpRegion': env.gcpRegion,
            'kClusterName': env.project,
            'gcp_credentials_file': env.gcp_credentials_file.name,
            'project_id': env.project_id,
        }
  
    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        """
        Check GCloud instance type and image id availability in specified
        region.
        """
        # Instantiate a new CloudCli
        cloud_cli = CloudCli(env.cloud, bin_path=self.cloud_tools_bin_path)

        # Build a list of instance_type accordingly to the specs
        node_types = ['postgres_server']

        # Check instance type and image availability
        for instance_type in self._get_instance_types(node_types):
            with AM(
                "Checking instance type %s availability in %s"
                % (instance_type, env.gcloud_region)
            ):
                cloud_cli.check_instance_type_availability(
                    instance_type, env.gcloud_region
                )
        # Check availability of the image
        with AM(
            "Checking image %s availability"
            % self.terraform_vars['gcloud_image']
        ):
            cloud_cli.cli.check_image_availability(
                self.terraform_vars['gcloud_image']
            )

    def provision(self, env):
        self.gcloud_gke_provision(env)

    def deploy(self, no_install_collection,
               pre_deploy_ansible=None,
               post_deploy_ansible=None,
               skip_main_playbook=False,
               disable_pipelining=False):
        self.gcloud_gke_deploy(
            no_install_collection,
            pre_deploy_ansible,
            post_deploy_ansible,
            skip_main_playbook,
            disable_pipelining
        )

    def destroy(self):
        self.gcloud_gke_destroy()            
