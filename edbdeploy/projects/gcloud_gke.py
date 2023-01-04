import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..project import Project
from ..render import build_inventory_yml

from ..ansible import AnsibleCli
from ..terraform import TerraformCli
from subprocess import CalledProcessError
from ..system import exec_shell


class GCloudGKEProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(GCloudGKEProject, self).__init__('gcloud-gke', name, env, bin_path)
        # Use Gcloud terraform code
        self.terraform_path = os.path.join(self.terraform_share_path, 'gcloud-gke')

    def configure(self, env):
        # self.gcloud_gke_configure(env)
        """
        Configure sub-comand for Google Cloud GKE environment
        """
        # Load specifications
        env.cloud_spec = self._load_cloud_specs(env)
                
        # Copy the kubernetes role in ansible project directory
        ansible_roles_path = os.path.join(self.project_path, "roles")

        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)
        # Load terraform variables
        self._load_terraform_vars()
        # Load cnpType
        cnpType = self.terraform_vars['cnpType']        
        # Assign ansible playbook to copy
        if cnpType == 'pg':
            self.ansible_vars = { 'reference_architecture': 'setup_cloudnativepg_sandbox', }
        elif cnpType == 'postgres':
            self.ansible_vars = { 'reference_architecture': 'setup_cloudnativepostgres_sandbox', }
        else:
            self.ansible_vars = { 'reference_architecture': 'setup_cloudnativepg_sandbox', }
               
        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()
        
        # Initialize Terraform so that a project removal 
        # can immediately be followed successfully
        # Load terraform variables
        self._load_terraform_vars()
        
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )
        
        with AM("Google Cloud GKE Terraform project initialization"):
            self.update_state('terraform', 'INITIALIZATING')
            terraform.init()
            self.update_state('terraform', 'INITIALIZATED')

        # note: we do not raise any AnsibleCliError from this function
        # because AnsibleCliError are used to trigger stuffs when they are
        # catched. In this case, we do not want trigger anything if something
        # fails.
        try:
            output = exec_shell(
                [self.bin("ansible-playbook"), "--version"],
                environ=self.environ
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "Terraform executable seems to be missing. Please install it "
                "or check your PATH variable"
            )         
        
    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)

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
        # self.gcloud_gke_provision(env)

        # Load terraform variables
        self._load_terraform_vars()
        
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        with AM("Google Cloud GKE Terraform project initialization"):
            self.update_state('terraform', 'INITIALIZATING')
            terraform.init()
            self.update_state('terraform', 'INITIALIZATED')

        with AM("Google Cloud GKE Terraform project provisioning"):
            self.update_state('terraform', 'PROVISIONING')
            terraform.apply(self.terraform_vars_file)
            self.update_state('terraform', 'PROVISIONED')

        # Assign region from Terraform variables
        region = self.terraform_vars['gcpRegion']
        kClusterName = self.terraform_vars['kClusterName']        
        # Get Kubernetes Cluster credentials
        output = exec_shell(
            [self.bin("gcloud"), "container", "clusters", "get-credentials", 
                kClusterName, "--region", region],
            environ=self.environ
        )

    def deploy(self, no_install_collection,
               pre_deploy_ansible=None,
               post_deploy_ansible=None,
               skip_main_playbook=False,
               disable_pipelining=False):
        """
        Deployment method for the Google Cloud GKE environments
        """
        # Load terraform variables
        self._load_terraform_vars()

        # Assign region from Terraform variables
        region = self.terraform_vars['gcpRegion']
        kClusterName = self.terraform_vars['kClusterName']        
        # Get Kubernetes Cluster credentials
        output = exec_shell(
            [self.bin("gcloud"), "container", "clusters", "get-credentials", 
                kClusterName, "--region", region],
            environ=self.environ
        )

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )

        if not skip_main_playbook:
            self.update_state('ansible', 'DEPLOYING')
            with AM("Deploying components with Ansible"):
                ansible.run_playbook_minimal(
                    self.cloud,
                    self.ansible_playbook,
                    disable_pipelining=disable_pipelining,
                )
            self.update_state('ansible', 'DEPLOYED')

    def destroy(self):
    #    self.gcloud_gke_destroy()
        """
        GCloud GKE destroy method
        """
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )

        with AM("Destroying cloud resources"):
            self.update_state('terraform', 'DESTROYING')
            terraform.destroy(self.terraform_vars_file)
            self.update_state('terraform', 'DESTROYED')
            self.update_state('ansible', 'UNKNOWN')
            




    """
    Kubernetes related methods
    """
    def configure(self, env):
        """
        Configure sub-comand for Google Cloud GKE environment
        """
        # Load specifications
        env.cloud_spec = self._load_cloud_specs(env)
                
        # Copy the kubernetes role in ansible project directory
        ansible_roles_path = os.path.join(self.project_path, "roles")

        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)
        # Load terraform variables
        self._load_terraform_vars()
        # Load cnpType
        cnpType = self.terraform_vars['cnpType']        
        # Assign ansible playbook to copy
        match cnpType:
            case 'pg':
                self.ansible_vars = { 'reference_architecture': 'setup_cloudnativepg_sandbox', }
            case 'postgres':
                self.ansible_vars = { 'reference_architecture': 'setup_cloudnativepostgres_sandbox', }
            case _:
                self.ansible_vars = { 'reference_architecture': 'setup_cloudnativepg_sandbox', }
        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()
        
        # Initialize Terraform so that a project removal 
        # can immediately be followed successfully
        # Load terraform variables
        self._load_terraform_vars()
        
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )
        
        with AM("Google Cloud GKE Terraform project initialization"):
            self.update_state('terraform', 'INITIALIZATING')
            terraform.init()
            self.update_state('terraform', 'INITIALIZATED')

        # note: we do not raise any AnsibleCliError from this function
        # because AnsibleCliError are used to trigger stuffs when they are
        # catched. In this case, we do not want trigger anything if something
        # fails.
        try:
            output = exec_shell(
                [self.bin("ansible-playbook"), "--version"],
                environ=self.environ
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "Terraform executable seems to be missing. Please install it "
                "or check your PATH variable"
            )            

    def gcloud_gke_provision(self, env):
        # Load terraform variables
        self._load_terraform_vars()
        
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        with AM("Google Cloud GKE Terraform project initialization"):
            self.update_state('terraform', 'INITIALIZATING')
            terraform.init()
            self.update_state('terraform', 'INITIALIZATED')

        with AM("Google Cloud GKE Terraform project provisioning"):
            self.update_state('terraform', 'PROVISIONING')
            terraform.apply(self.terraform_vars_file)
            self.update_state('terraform', 'PROVISIONED')

        # Assign region from Terraform variables
        region = self.terraform_vars['gcpRegion']
        kClusterName = self.terraform_vars['kClusterName']        
        # Get Kubernetes Cluster credentials
        output = exec_shell(
            [self.bin("gcloud"), "container", "clusters", "get-credentials", 
                kClusterName, "--region", region],
            environ=self.environ
        )            
            
    def deploy(self, no_install_collection, pre_deploy_ansible=None,
                   post_deploy_ansible=None, skip_main_playbook=False,
                   disable_pipelining=False):
        """
        Deployment method for the Google Cloud GKE environments
        """
        # Load terraform variables
        self._load_terraform_vars()

        # Assign region from Terraform variables
        region = self.terraform_vars['gcpRegion']
        kClusterName = self.terraform_vars['kClusterName']        
        # Get Kubernetes Cluster credentials
        output = exec_shell(
            [self.bin("gcloud"), "container", "clusters", "get-credentials", 
                kClusterName, "--region", region],
            environ=self.environ
        )

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )

        if not no_install_collection:
            with AM(
                "Installing Ansible collection %s"
                % self.ansible_collection_name
            ):
                ansible.install_collection(self.ansible_collection_name)
            with AM(
                "Installing Kubernetes Core Ansible collection %s"
                % self.k8s_core_ansible_collection_name
            ):
                ansible.install_collection(self.k8s_core_ansible_collection_name)
            with AM(
                "Installing Kubernetes Community Ansible collection %s"
                % self.k8s_community_ansible_collection_name
            ):
                ansible.install_collection(self.k8s_community_ansible_collection_name)

        if not skip_main_playbook:
            self.update_state('ansible', 'DEPLOYING')
            with AM("Deploying components with Ansible"):
                ansible.run_playbook_minimal(
                    self.cloud,
                    self.ansible_playbook,
                    disable_pipelining=disable_pipelining,
                )
            self.update_state('ansible', 'DEPLOYED')

    def destroy(self):
        # self.gcloud_gke_destroy()
        """
        GCloud GKE destroy method
        """
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )

        with AM("Destroying cloud resources"):
            self.update_state('terraform', 'DESTROYING')
            terraform.destroy(self.terraform_vars_file)
            self.update_state('terraform', 'DESTROYED')
            self.update_state('ansible', 'UNKNOWN')        
