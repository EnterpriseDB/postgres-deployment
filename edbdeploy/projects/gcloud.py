import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..project import Project
from ..render import build_inventory_yml, build_ansible_inventory
import re


class GCloudProject(Project):
    def __init__(self, name, env, bin_path=None, using_edbterraform=True):
        super(GCloudProject, self).__init__('gcloud', name, env, bin_path, using_edbterraform)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        ######################################################
        # Build the vars files for Terraform and Ansible
        # _build_terraform_vars override below
        super()._build_terraform_files()
        ######################################################
        super()._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        super()._copy_ansible_playbook()
        # Check Cloud Instance type and Image availability.
        self._check_instance_image(env)

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

    def hook_inventory_yml(self, vars):
        # Hook function called by Project.provision()
        with AM("Generating the inventory.yml file"):
            if self.using_edbterraform:
                template_vars = dict()
                template_vars['vars'] = vars
                server_vars = super()._load_terraform_outputs()
                server_vars = server_vars.get('servers')
                template_vars['servers'] = server_vars.get('machines', {})
                build_ansible_inventory(
                    self.project_path,
                    vars=template_vars
                )
            else:
                build_inventory_yml(
                    self.ansible_inventory,
                    super()._get_servers_filepath(),
                    vars=vars
                )

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._iaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for GCloud provisioning
        """
        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        # Configure project specific terraform variables
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']
        hammerdb = env.cloud_spec['hammerdb_server']
        bdr = env.cloud_spec['bdr_server']
        bdr_witness = env.cloud_spec['bdr_witness_server']

        self.terraform_vars.update({
            'gcloud_image': os['image'],
            'gcloud_region': env.gcloud_region,
            'gcloud_credentials': env.gcloud_credentials.name if env.gcloud_credentials else None,
            'gcloud_project_id': env.gcloud_project_id,
        })
        self.terraform_vars['postgres_server'].update({
            'additional_volumes': pg['additional_volumes'],
            'instance_type': pg['instance_type'],
            'volume': pg['volume'],
        })

        # set variables for use with edbterraform
        cloud_cli = CloudCli(self.cloud_provider, bin_path=self.cloud_tools_bin_path)
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
        self.terraform_vars['created_by'] = cloud_cli.cli.get_caller_info()
        # ports needed
        self.terraform_vars['service_ports'], self.terraform_vars['region_ports'] = super()._get_default_ports()
        self.terraform_vars['image'] = dict()
        self.terraform_vars['image']['name'] = self.terraform_vars['gcloud_image']
        self.terraform_vars['image']['ssh_user'] = self.terraform_vars['ssh_user']
        self.terraform_vars['region'] = self.terraform_vars['gcloud_region']
        # create a set of zones from each machine's instance type and region availability zone  
        instance_types: set = {
            values['instance_type'] for key, values in self.terraform_vars.items()
            if any(substr in key for substr in ['dbt2_client', 'dbt2_driver', '_server']) and
            isinstance(values, dict) and
            values.get('count', 0) >= 1
            and values.get('instance_type')
        }
        filtered_zones: set = {zone for instance in instance_types for zone in cloud_cli.check_instance_type_availability(instance, self.terraform_vars['gcloud_region'])}
        filtered_zones.intersection_update(cloud_cli.cli.get_available_zones(self.terraform_vars['gcloud_region']))
        self.terraform_vars['zones'] = list(filtered_zones)

    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        """
        Check GCloud instance type and image id availability in specified
        region.
        """
        # Instanciate a new CloudCli
        cloud_cli = CloudCli(env.cloud, bin_path=self.cloud_tools_bin_path)

        # Build a list of instance_type accordingly to the specs
        node_types = ['postgres_server', 'pem_server', 'hammerdb_server',
                      'barman_server', 'pooler_server']

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
