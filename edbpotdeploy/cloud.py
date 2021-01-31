import logging
import json
import time
from subprocess import CalledProcessError

from .system import exec_shell


class CloudCliError(Exception):
    pass


class AWSCli:
    def __init__(self):
        pass

    def check_instance_type_availability(self, instance_type, region):
        try:
            output = exec_shell([
                "aws",
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
                "aws",
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
                "aws",
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
    def __init__(self):
        pass

    def check_instance_type_availability(self, instance_type, region):
        try:
            output = exec_shell([
                "az",
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
                "az",
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
                "az",
                "vm",
                "wait",
                "--ids",
                "$(az vm list -g \"%s_edb_resource_group\" --query \"[].id\" -o tsv)"
                % project_name,
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
        pass

    def check_instance_type_availability(self, instance_type, region):
        try:
            output = exec_shell([
                "gcloud",
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
                "gcloud",
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
                    "gcloud",
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

    def __init__(self, cloud):
        self.cloud = cloud
        if self.cloud == 'aws':
            self.cli = AWSCli()
        elif self.cloud == 'azure':
            self.cli = AzureCli()
        elif self.cloud == 'gcloud':
            self.cli = GCloudCli()
        else:
            raise Exception("Unknown cloud %s", self.cloud)

    def check_instance_type_availability(self, instance_type, region):
        return self.cli.check_instance_type_availability(instance_type, region)
