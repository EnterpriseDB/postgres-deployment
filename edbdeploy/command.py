import logging
from .project import Project
from .projects.aws import AWSProject
from .projects.aws_rds import AWSRDSProject
from .projects.aws_rds_aurora import AWSRDSAuroraProject
from .projects.azure import AzureProject
from .projects.azure_db import AzureDBProject
from .projects.gcloud import GCloudProject
from .projects.gcloud_sql import GCloudSQLProject
from .projects.baremetal import BaremetalProject
from .projects.vmware import VMwareProject
from .projects.virtualbox import VirtualBoxProject
# POT
from .projects.aws_pot import AWSPOTProject
from .projects.azure_pot import AzurePOTProject
from .projects.gcloud_pot import GCloudPOTProject


class CommanderError(Exception):
    pass

class Commander:
    def __init__(self, env):
        self.env = env
        self.project = None
        if getattr(self.env, 'project', False):
            if self.env.cloud == 'aws':
                self.project = AWSProject(self.env.project, self.env)
            elif self.env.cloud == 'azure':
                self.project = AzureProject(self.env.project, self.env)
            elif self.env.cloud == 'gcloud':
                self.project = GCloudProject(self.env.project, self.env)
            elif self.env.cloud == 'gcloud-sql':
                self.project = GCloudSQLProject(self.env.project, self.env)
            elif self.env.cloud == 'baremetal':
                self.project = BaremetalProject(self.env.project, self.env)
            elif self.env.cloud == 'vmware':
                self.project = VMwareProject(self.env.project, self.env)
            elif self.env.cloud == 'virtualbox':
                self.project = VirtualBoxProject(self.env.project, self.env)
            elif self.env.cloud == 'aws-rds':
                self.project = AWSRDSProject(self.env.project, self.env)
            elif self.env.cloud == 'aws-rds-aurora':
                self.project = AWSRDSAuroraProject(self.env.project, self.env)
            elif self.env.cloud == 'azure-db':
                self.project = AzureDBProject(self.env.project, self.env)
            elif self.env.cloud == 'aws-pot':
                self.project = AWSPOTProject(self.env.project, self.env)
            elif self.env.cloud == 'azure-pot':
                self.project = AzurePOTProject(self.env.project, self.env)
            elif self.env.cloud == 'gcloud-pot':
                self.project = GCloudPOTProject(self.env.project, self.env)
            else:
                self.project = Project(
                    self.env.cloud, self.env.project, self.env
                )

    def _check_project_exists(self):
        if not self.project.exists():
            msg = "Project %s does not exist" % self.project.name
            logging.error(msg)
            raise CommanderError(msg)

    def execute(self):
        logging.info(
            "Executing command: %s %s", self.env.cloud, self.env.sub_command
        )

        if getattr(self, self.env.sub_command, False):
            getattr(self, self.env.sub_command)()
        else:
            raise CommanderError(
                "Sub-command %s not implemented" % self.env.sub_command
            )

    def configure(self):
        if self.project.exists():
            if self.env.force_configure:
                self.project.remove()
            else:
                msg = "Project %s already exists" % self.project.name
                logging.error(msg)
                raise CommanderError(msg)

        # Check 3rd party SW versions
        self.project.check_versions()

        logging.info("Project configuration...")
        self.project.create()
        self.project.configure(self.env)
        logging.info("End of project configuration")

    def logs(self):
        self._check_project_exists()
        logging.info("Fetching logs for project %s", self.project.name)
        self.project.show_logs(self.env.tail)

    def remove(self):
        self._check_project_exists()
        logging.info("Removing project %s", self.project.name)
        self.project.remove()

    def show(self):
        self._check_project_exists()
        logging.info("Showing project %s configuration", self.project.name)
        self.project.show_configuration()

    def provision(self):
        self._check_project_exists()

        # Check 3rd party SW versions
        self.project.check_versions()

        logging.info("Provisioning machines for project %s", self.project.name)
        self.project.provision(self.env)

    def destroy(self):
        self._check_project_exists()

        # Check 3rd party SW versions
        self.project.check_versions()

        logging.info("Destroying machines for project %s", self.project.name)
        self.project.destroy()

    def deploy(self):
        self._check_project_exists()

        # Check 3rd party SW versions
        self.project.check_versions()

        logging.info("Deploying components for project %s", self.project.name)
        self.project.deploy(self.env.no_install_collection,
                            self.env.pre_deploy_ansible,
                            self.env.post_deploy_ansible,
                            self.env.skip_main_playbook,
                            self.env.disable_pipelining)

    def display(self):
        self._check_project_exists()
        logging.info("Displaying project %s details", self.project.name)

        # Check 3rd party SW versions
        self.project.check_versions()

        self.project.display_details()

    def passwords(self):
        self._check_project_exists()
        logging.info("Display project %s passwords details", self.project.name)
        self.project.display_passwords()

    def list(self):
        logging.info("Listing project for cloud %s", self.env.cloud)
        if self.env.cloud == 'vmware':
            VMwareProject.list(self.env.cloud)
            return
        if self.env.cloud == 'virtualbox':
            VirtualBoxProject.list(self.env.cloud)
            return
        else:
            Project.list(self.env.cloud)

    def specs(self):
        logging.info("Showing default specs. for cloud %s", self.env.cloud)
        Project.show_specs(
            self.env.cloud,
            getattr(self.env, 'reference_architecture', None)
        )

    def setup(self):
        logging.info(
            "Executing the setup command for the %s cloud", self.env.cloud
        )
        Project.create_cloud_tools_bin_dir()
        Project.setup_tools(self.env.cloud)

    def ssh(self):
        self._check_project_exists()

        # Checking the node name and fetching SSH parameters
        (host_address, ssh_user, ssh_priv_key) = self.project.prepare_ssh(
            self.env.host
        )

        logging.info(
            "Opening SSH session on %s (%s)", self.env.host, host_address
        )
        self.project.ssh(host_address, ssh_user, ssh_priv_key)

    def get_ssh_keys(self):
        self._check_project_exists()
        self.project.get_ssh_keys()

    def update_route53_key(self):
        self._check_project_exists()
        self.project.pot_update_route53_key(
            self.env.route53_access_key, self.env.route53_secret, self.env.route53_session_token
        )
