import logging
import json
import os
import re
import textwrap
import time
from subprocess import CalledProcessError

from .installation import (
    build_tmp_install_script,
    execute_install_script,
    uname,
)
from .system import exec_shell
from .errors import CloudCliError
from . import check_version, to_str


class AWSCli:
    def __init__(self, bin_path=None):
        # aws CLI supported versions interval
        self.min_version = (0, 0, 0)
        self.max_version = (1, 22, 34)
        # Path to look up for executable
        self.bin_path = None
        # Force aws CLI binary path if bin_path exists and contains
        # aws file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'aws')):
                self.bin_path = bin_path

        pass

    def check_version(self):
        """
        Verify aws CLI version, based on the interval formed by min_version and
        max_version.
        aws CLI version is fetched using the command: aws --version
        """
        try:
            output = exec_shell([self.bin("aws"), "--version"])
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "aws CLI executable seems to be missing. Please install it or "
                "check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^aws-cli\/([0-9]+)\.([0-9]+)\.([0-9]+) ")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise Exception("Unable to parse aws CLI version")

        logging.info("aws CLI version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.min_version, self.max_version):
            raise Exception(
                "aws CLI version %s not supported, must be between %s and %s"
                % (to_str(version), to_str(self.min_version),
                   to_str(self.max_version)))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def check_instance_type_availability(self, instance_type, region) -> list:
        try:
            output = exec_shell([
                self.bin("aws"),
                "ec2",
                "describe-instance-type-offerings",
                "--location-type availability-zone",
                "--filters Name=instance-type,Values=%s" % instance_type,
                "--region %s" % region,
                "--output json"
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            instance_type_offerings = result.get("InstanceTypeOfferings", [])
            if len(instance_type_offerings) == 0:
                raise CloudCliError(
                    "Instance type %s not available in region %s"
                    % (instance_type, region)
                )
            aws_var = 'Location'
            filtered = [value[aws_var] for value in instance_type_offerings if value.get(aws_var)]
            if len(filtered) == 0:
                raise CloudCliError('Variable %s not found' % (aws_var))
            return filtered

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def get_image_info(self, image, region):
        try:
            output = exec_shell([
                self.bin("aws"),
                "ec2",
                "describe-images",
                "--filters Name=name,Values=\"%s\"" % image,
                "--query 'sort_by(Images, &Name)[-1]'",
                "--region %s" % region,
                "--output json"
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)

            if result.get('State') == 'available':
                return result

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def get_image_id(self, image, region):
        result = self.get_image_info(image, region)
        return result.get('ImageId')
    
    def get_image_owner(self, image, region):
        result = self.get_image_info(image, region)
        return result.get('OwnerId')
    
    def get_caller_info(self) -> str:
        try:
            output = exec_shell([
                self.bin("aws"),
                "sts",
                "get-caller-identity",
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)

            return result.get('UserId')

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def get_available_zones(self, region) -> list:
        try:
            output = exec_shell([
                self.bin("aws"),
                "ec2",
                "describe-availability-zones",
                "--filters Name=state,Values=available",
                "--region %s" % region,
                "--output json"
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            availability_zones = result.get('AvailabilityZones', [])
            if len(availability_zones) == 0:
                raise CloudCliError(
                    "Region %s has no available zones"
                    % (region)
                )
            aws_var = 'ZoneName'
            filtered = [value[aws_var] for value in availability_zones if value.get(aws_var)]
            if len(filtered) == 0:
                raise CloudCliError('Variable %s not found' % (aws_var))
            return filtered

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def check_instances_availability(self, region):
        try:
            output = exec_shell([
                self.bin("aws"),
                "ec2",
                "wait",
                "instance-status-ok",
                "--region %s" % region
            ])
            logging.debug("Command output: %s", output.decode("utf-8"))

        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def install(self, installation_path):
        """
        AWS CLI installation
        """
        # Installation bash script content
        installation_script = textwrap.dedent("""
            #!/bin/bash
            set -eu

            mkdir -p {path}/aws/{version}
            python3 -m venv {path}/aws/{version}
            sed -i.bak 's/$1/${{1:-}}/' {path}/aws/{version}/bin/activate
            source {path}/aws/{version}/bin/activate
            python3 -m pip install "awscli=={version}"
            deactivate
            rm -f {path}/bin/aws
            ln -sf {path}/aws/{version}/bin/aws {path}/bin/.
        """)

        # Generate the installation script as an executable tempfile
        script_name = build_tmp_install_script(
            installation_script.format(
                path=installation_path,
                version='.'.join(str(i) for i in self.max_version),
            )
        )

        # Execute the installation script
        execute_install_script(script_name)


class AWSRDSCli(AWSCli):
    def check_instance_type_availability(self, instance_type, region):
        try:
            output = exec_shell([
                self.bin("aws"),
                "rds",
                "describe-reserved-db-instances-offerings",
                "--product-description postgresql",
                "--region %s" % region,
                "--db-instance-class %s" % instance_type,
                "--output json"
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            if len(result["ReservedDBInstancesOfferings"]) == 0:
                raise CloudCliError(
                    "Instance type %s not available in region %s"
                    % (instance_type, region)
                )
        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )


class AWSRDSAuroraCli(AWSRDSCli):
    pass


class AzureCli:
    def __init__(self, bin_path=None):
        # azure CLI supported versions interval
        self.min_version = (0, 0, 0)
        self.max_version = (2, 44, 1)
        # Path to look up for executable
        self.bin_path = None
        # Force azure CLI binary path if bin_path exists and contains
        # az file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'az')):
                self.bin_path = bin_path

    def check_version(self):
        """
        Verify azure CLI version, based on the interval formed by min_version and
        max_version.
        azure CLI version is fetched using the command: az --version
        """
        try:
            output = exec_shell([self.bin("az"), "--version"])
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "azure CLI executable seems to be missing. Please install it or "
                "check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^azure-cli\s+([0-9]+)\.([0-9]+)\.([0-9]+)")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise Exception("Unable to parse azure CLI version")

        logging.info("azure CLI version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.min_version, self.max_version):
            raise Exception(
                "azure CLI version %s not supported, must be between %s and %s"
                % (to_str(version), to_str(self.min_version),
                   to_str(self.max_version)))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def check_instance_type_availability(self, instance_type, region):
        try:
            output = exec_shell([
                self.bin("az"),
                "vm",
                "list-sizes",
                "--location %s" % region,
                "--query \"[?name == '%s']\"" % instance_type,
                "--output json"
            ])
            
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            if len(result) == 0:
                raise CloudCliError(
                    "Instance type %s not available in region %s"
                    % (instance_type, region)
                )
            zones = self.get_available_zones(instance_type, region)
            # Not all regions have zones yet so set to 0 for handling
            return zones if zones else ['0']
        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def check_image_availability(self, publisher, offer, sku, region):
        try:
            output = exec_shell([
                self.bin("az"),
                "vm",
                "image",
                "list",
                "--all",
                "-p \"%s\"" % publisher,
                "-f \"%s\"" % offer,
                "-s \"%s\"" % sku,
                "-l %s" % region,
                "--query",
                "\"[?offer == '%s' && sku =='%s']\"" % (offer, sku),
                "--output json"
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            if len(result) == 0:
                raise CloudCliError(
                    "Image %s:%s:%s not available in region %s"
                    % (publisher, offer, sku, region)
                )
            return result[0]
        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def check_instances_availability(self, project_name):
        try:
            output = exec_shell([
                self.bin("az"),
                "vm",
                "wait",
                "--ids",
                "$(%s vm list -g \"%s_edb_resource_group\" --query \"[].id\" -o tsv)"
                % (self.bin("az"), project_name),
                "--created"
            ])
            logging.debug("Command output: %s", output.decode("utf-8"))
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def accept_terms(self, publisher, offer, sku, version):
        try:
            output = exec_shell([
                self.bin("az"),
                "vm",
                "image",
                "terms",
                "accept",
                "--urn %s:%s:%s:%s" % (publisher, offer, sku, version),
            ])
            logging.debug("Command output: %s", output.decode("utf-8"))

        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def install(self, installation_path):
        """
        Azure CLI installation
        """
        # Installation bash script content
        installation_script = textwrap.dedent("""
            #!/bin/bash
            set -eu

            mkdir -p {path}/azure/{version}
            python3 -m venv {path}/azure/{version}
            sed -i.bak 's/$1/${{1:-}}/' {path}/azure/{version}/bin/activate
            source {path}/azure/{version}/bin/activate
            # cryptography should be pinned to 3.3.2 because the next
            # version introduces rust as a dependency for building it and
            # breaks compatiblity with some pip versions.
            # ref: https://github.com/Azure/azure-cli/issues/16858
            python3 -m pip install "cryptography==3.3.2"
            python3 -m pip install "azure-cli=={version}"
            deactivate
            rm -f {path}/bin/az
            ln -sf {path}/azure/{version}/bin/az {path}/bin/.
        """)

        # Generate the installation script as an executable tempfile
        script_name = build_tmp_install_script(
            installation_script.format(
                path=installation_path,
                version='.'.join(str(i) for i in self.max_version),
            )
        )

        # Execute the installation script
        execute_install_script(script_name)

    def get_available_zones(self, instance_type, region) -> list:
        '''
        Get a list of available zones
        '''
        try:
            output = exec_shell([
                self.bin("az"),
                "vm",
                "list-skus",
                "--location %s" % region,
                "--query \"[?name == '%s']\"" % instance_type,
                "--output json"
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            if len(result) == 0:
                raise CloudCliError(
                    "Instance type %s not available in region %s"
                    % (instance_type, region)
                )
            zones = result[0]['locationInfo'][0]['zones']
            return zones
        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )
        return [1,2,3]

    def get_caller_info(self) -> str:
        try:
            output = exec_shell([
                self.bin("az"),
                "account",
                "show",
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            # contains email so split and replace any non-alphanumerics so it can be used as a tag
            name = re.sub(r'\W+', '-', result['user']['name'].split('@')[0]).lower()
            return name

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

class AzureDBCli(AzureCli):
    pass


class GCloudCli:
    def __init__(self, bin_path=None):
        # gcloud CLI supported versions interval
        self.min_version = (0, 0, 0)
        self.max_version = (413, 0, 0)
        # Path to look up for executable
        self.bin_path = None
        # Force gcloud CLI binary path if bin_path exists and contains
        # gcloud file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'gcloud')):
                self.bin_path = bin_path

    def check_version(self):
        """
        Verify gcloud CLI version, based on the interval formed by min_version and
        max_version.
        gcloud CLI version is fetched using the command: gcloud --version
        """
        try:
            output = exec_shell([self.bin("gcloud"), "--version"])
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "gcloud CLI executable seems to be missing. Please install it or "
                "check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^Google Cloud SDK ([0-9]+)\.([0-9]+)\.([0-9]+)")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise Exception("Unable to parse gcloud CLI version")

        logging.info("gcloud CLI version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.min_version, self.max_version):
            raise Exception(
                "gcloud CLI version %s not supported, must be between %s and %s"
                % (to_str(version), to_str(self.min_version),
                   to_str(self.max_version)))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def check_instance_type_availability(self, instance_type, region):
        try:
            output = exec_shell([
                self.bin("gcloud"),
                "compute",
                "machine-types",
                "list",
                "--filter=\"name=%s zone:%s*\"" % (instance_type, region),
                "--format=json"
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            if len(result) == 0:
                raise CloudCliError(
                    "Instance type %s not available in region %s"
                    % (instance_type, region)
                )
            gcloud_var = 'zone'
            filtered = [value[gcloud_var] for value in result if value.get(gcloud_var)]
            if len(filtered) == 0:
                raise CloudCliError('Variable %s not found' % (gcloud_var))
            return filtered

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def check_image_availability(self, image):
        try:
            cmd = [
                self.bin("gcloud"),
                "compute",
                "images",
                "list",
                "--filter=\"family=%s\"" % image,
                "--format=json"
            ]
            if image == 'rocky-linux-8':
                cmd = cmd + [
                        '--no-standard-images',
                        '--project=rocky-linux-cloud'
                        ]
            output = exec_shell(cmd)
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            if len(result) == 0 or result[0]['status'] != 'READY':
                raise CloudCliError("Image %s not available" % image)
        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def check_instances_availability(self, project_name, region, node_count):
        try_count = 0
        try_max = 5
        try_nap_time = 2
        while True:
            if try_count >= try_max:
                raise CloudCliError(
                    "Unable to check instances availability after %s trys"
                    % try_count
                )

            try_count += 1

            try:
                output = exec_shell([
                    self.bin("gcloud"),
                    "compute",
                    "instances",
                    "list",
                    "--filter=\"name:%s-* zone ~ %s-[a-z] status=RUNNING\""
                    % (project_name, region),
                    "--format=json"
                ])
                result = json.loads(output.decode("utf-8"))
                logging.debug("Command output: %s", result)

                if (len(result) >= node_count):
                    # Number of ready instances is good, just break the loop
                    break

                time.sleep(try_nap_time)

            except ValueError:
                # JSON decoding error
                logging.error("Failed to decode JSON data")
                logging.error("Output: %s", output.decode("utf-8"))
                raise CloudCliError(
                    "Failed to decode JSON data, please check the logs for "
                    "details"
                )
            except CalledProcessError as e:
                logging.error("Failed to execute the command: %s", e.cmd)
                logging.error("Return code is: %s", e.returncode)
                logging.error("Output: %s", e.output)
                raise CloudCliError(
                    "Failed to execute the following command, please check the"
                    " logs for details: %s" % e.cmd
                )

    def install(self, installation_path):
        """
        GCloud CLI installation
        """
        # Installation bash script content
        installation_script = textwrap.dedent("""
            #!/bin/bash
            set -eu

            mkdir -p {path}/gcloud/{version}
            wget -q https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-{version}-{os_flavor}-x86_64.tar.gz -O /tmp/google-cloud-sdk.tar.gz
            tar xvzf /tmp/google-cloud-sdk.tar.gz -C {path}/gcloud/{version}
            rm /tmp/google-cloud-sdk.tar.gz
            rm -f {path}/bin/gcloud
            ln -sf {path}/gcloud/{version}/google-cloud-sdk/bin/gcloud {path}/bin/.
        """)

        # Generate the installation script as an executable tempfile
        script_name = build_tmp_install_script(
            installation_script.format(
                path=installation_path,
                version='.'.join(str(i) for i in self.max_version),
                os_flavor=uname().lower()
            )
        )

        # Execute the installation script
        execute_install_script(script_name)

    def get_caller_info(self) -> str:
        try:
            output = exec_shell([
                self.bin("gcloud"),
                "config",
                "get-value",
                "account",
                "--format json",
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            # contains email so split and replace any non-alphanumerics so it can be used as a tag
            name = re.sub(r'\W+', '-', result.split('@')[0]).lower()
            return name

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )
        
    def get_available_zones(self, region) -> list:
        try:
            output = exec_shell([
                self.bin("gcloud"),
                "compute",
                "zones",
                "list",
                "--format json",
                "--filter=\"status=%s region:%s*\"" % ("UP", region),
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            if len(result) == 0:
                raise CloudCliError(
                    "Region %s has no available zones"
                    % (region)
                )
            gcloud_var = 'name'
            filtered = [value[gcloud_var] for value in result if value.get(gcloud_var)]
            if len(filtered) == 0:
                raise CloudCliError('Variable %s not found' % (gcloud_var))
            return filtered

        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CloudCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CloudCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

class GCloudSQLCli(GCloudCli):
    pass

class CloudCli:

    def __init__(self, cloud, bin_path):
        self.cloud = cloud
        if self.cloud in ['aws', 'aws-pot']:
            self.cli = AWSCli(bin_path)
        elif self.cloud == 'aws-rds':
            self.cli = AWSRDSCli(bin_path)
        elif self.cloud == 'aws-rds-aurora':
            self.cli = AWSRDSAuroraCli(bin_path)
        elif self.cloud in ['azure', 'azure-pot']:
            self.cli = AzureCli(bin_path)
        elif self.cloud == 'azure-db':
            self.cli = AzureDBCli(bin_path)
        elif self.cloud in ['gcloud', 'gcloud-pot']:
            self.cli = GCloudCli(bin_path)
        elif self.cloud == 'gcloud-sql':
            self.cli = GCloudSQLCli(bin_path)
        else:
            raise Exception("Unknown cloud %s" % self.cloud)

    def check_instance_type_availability(self, instance_type, region):
        return self.cli.check_instance_type_availability(instance_type, region)

    def check_version(self):
        self.cli.check_version()
