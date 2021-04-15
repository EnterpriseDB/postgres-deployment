import logging
from .project import Project

class CommanderError(Exception):
    pass

class Commander:
    def __init__(self, env):
        self.env = env
        self.project = None
        if getattr(self.env, 'project', False):
            self.project = Project(self.env.cloud, self.env.project)

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
        self.project.provision()

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
                            self.env.skip_main_playbook)

    def display(self):
        self._check_project_exists()
        logging.info("Desplaying project %s details", self.project.name)

        # Check 3rd party SW versions
        self.project.check_versions()

        self.project.display_details()

    def passwords(self):
        self._check_project_exists()
        logging.info("Display project %s passwords details", self.project.name)
        self.project.display_passwords()

    def list(self):
        logging.info("Listing project for cloud %s", self.env.cloud)
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
