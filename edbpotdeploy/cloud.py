import logging
import json
import os
import re
import time
from subprocess import CalledProcessError

from .system import exec_shell


class CloudCliError(Exception):
    pass


class AWSCli:
    def __init__(self, bin_path=None):
        # aws CLI supported versions interval
        self.min_version = (0, 0, 0)
        self.max_version = (1, 19, 18)
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

         # Verify if the version fetched is supported
         for i in range(0, 3):
             min = self.min_version[i]
             max = self.max_version[i]

             if version[i] < max:
                 # If current digit is below the maximum value, no need to
                 # check others digits, we are good
                 break

             if version[i] not in list(range(min, max + 1)):
                 raise Exception(
                     ("aws CLI version %s not supported, must be between %s and"
                      " %s") % (
                         '.'.join(map(str, version)),
                         '.'.join(map(str, self.min_version)),
                         '.'.join(map(str, self.max_version)),
                     )
                 )

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
            if len(result["InstanceTypeOfferings"]) == 0:
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

    def get_image_id(self, image, region):
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
                return result.get('ImageId')

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


class AzureCli:
    def __init__(self, bin_path=None):
         # azure CLI supported versions interval
         self.min_version = (0, 0, 0)
         self.max_version = (2, 20, 0)
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
            output = exec_shell([self.bin(self.bin("az")), "--version"])
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
        pattern = re.compile(r"^azure-cli\s+([0-9]+)\.([0-9]+)\.([0-9]+)$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise Exception("Unable to parse azure CLI version")

        logging.info("azure CLI version: %s", '.'.join(map(str, version)))

        # Verify if the version fetched is supported
        for i in range(0, 3):
            min = self.min_version[i]
            max = self.max_version[i]

            if version[i] < max:
                # If current digit is below the maximum value, no need to
                # check others digits, we are good
                break

            if version[i] not in list(range(min, max + 1)):
                raise Exception(
                    ("azure CLI version %s not supported, must be between %s and"
                     " %s") % (
                        '.'.join(map(str, version)),
                        '.'.join(map(str, self.min_version)),
                        '.'.join(map(str, self.max_version)),
                    )
                )

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


class GCloudCli:
    def __init__(self):
        # gcloud CLI supported versions interval
        self.min_version = (0, 0, 0)
        self.max_version = (329, 0, 0)
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
            output = exec_shell([self.bin(self.bin("gcloud")), "--version"])
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

        # Verify if the version fetched is supported
        for i in range(0, 3):
            min = self.min_version[i]
            max = self.max_version[i]

            if version[i] < max:
                # If current digit is below the maximum value, no need to
                # check others digits, we are good
                break

            if version[i] not in list(range(min, max + 1)):
                raise Exception(
                    ("gcloud CLI version %s not supported, must be between %s and"
                     " %s") % (
                        '.'.join(map(str, version)),
                        '.'.join(map(str, self.min_version)),
                        '.'.join(map(str, self.max_version)),
                    )
                )

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
            output = exec_shell([
                self.bin("gcloud"),
                "compute",
                "images",
                "list",
                "--filter=\"family=%s\"" % image,
                "--format=json"
            ])
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


class CloudCli:

    def __init__(self, cloud, bin_path):
        self.cloud = cloud
        if self.cloud == 'aws':
            self.cli = AWSCli(bin_path)
        elif self.cloud == 'azure':
            self.cli = AzureCli(bin_path)
        elif self.cloud == 'gcloud':
            self.cli = GCloudCli(bin_path)
        else:
            raise Exception("Unknown cloud %s", self.cloud)

    def check_instance_type_availability(self, instance_type, region):
        return self.cli.check_instance_type_availability(instance_type, region)

    def check_version(self):
         self.cli.check_version()
