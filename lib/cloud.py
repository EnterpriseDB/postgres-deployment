import logging
import json
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


class GCloudCli:
    def __init__(self):
        pass


class CloudCli:

    def __init__(self, cloud):
        self.cloud = cloud
        if self.cloud == 'aws':
            self.cli = AWSCli()
        elif self.cloud == 'azure':
            self.cli = AWSCli()
        elif self.cloud == 'gcloud':
            self.cli = GCloudCli()
        else:
            raise Exception("Unknown cloud %s", self.cloud)

    def check_instance_type_availability(self, instance_type, region):
        return self.cli.check_instance_type_availability(instance_type, region)
