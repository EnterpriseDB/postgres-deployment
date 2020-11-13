package terraform

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

var templateLocation = ""

func RunTerraform(projectName string, project map[string]interface{}, arguements map[string]interface{}, customTemplateLocation *string) error {
	if customTemplateLocation != nil {
		templateLocation = *customTemplateLocation
	} else {
		path, err := os.Getwd()
		if err != nil {
			log.Println(err)
		}

		splitPath := strings.Split(path, "/")

		if len(splitPath) > 0 {
			splitPath = splitPath[:len(splitPath)-1]
		}

		splitPath = append(splitPath, "terraform")
		splitPath = append(splitPath, "aws")

		templateLocation = strings.Join(splitPath, "/")
	}

	project["instance_type"] = "c5.2xlarge"
	project["instance_image"] = "CentOS Linux 7 x86_64 HVM EBS*"

	setVariableAndTagNames()

	// os := "CentOS Linux 7 x86_64 HVM EBS*"
	// region := "us-east-2"
	// instanceCount := "1"
	// ssh := "~/.ssh/id_rsa.pub"
	// pem := "0"

	// _, err := checkImage("CentOS Linux 7 x86_64 HVM EBS*", region)
	// if err != nil {
	// 	return err
	// }

	if arguements["pre_run_checks"] != nil {
		preRunChecks := arguements["pre_run_checks"].(map[string]interface{})

		for i := 0; i < len(preRunChecks); i++ {
			iString := strconv.Itoa(i)
			check := preRunChecks[iString].(map[string]interface{})

			output, _ := preCheck(check, project)
			if check["output"] != nil {
				project[check["output"].(string)] = output
			}
		}
	}

	fmt.Println(project)

	// // checkType("c5.2xlarge", region)
	// _, err := checkImage("CentOS Linux 7 x86_64 HVM EBS*", region)
	// if err != nil {
	// 	return err
	// }

	// terraformWorkspace(projectName)

	// cmd := exec.Command("terraform", "init")
	// cmd.Dir = templateLocation

	// stdoutStderr, err := cmd.CombinedOutput()
	// if err != nil {
	// 	fmt.Printf("%s\n", stdoutStderr)
	// 	log.Fatal(err)
	// }

	// terraformApply(os, ami, region, instanceCount, ssh, projectName, pem)
	// checkInstanceStatus(region)

	// fmt.Printf("%s\n", stdoutStderr)

	return nil
}

func setVariableAndTagNames() error {
	tagsInput := "/tags.tf.template"
	tagsOutput := "/tags.tf"

	variablesInput := "/variables.tf.template"
	variablesOutput := "/variables.tf"

	tagTemplate, err := ioutil.ReadFile(fmt.Sprintf("%s%s", templateLocation, tagsInput))
	if err != nil {
		log.Fatal(err)
	}

	tagsReplaced := bytes.ReplaceAll(tagTemplate, []byte("PROJECT_NAME"), []byte("TEST_TEST"))

	err = ioutil.WriteFile(fmt.Sprintf("%s%s", templateLocation, tagsOutput), tagsReplaced, 0644)
	if err != nil {
		log.Fatal(err)
	}

	variableTemplate, err := ioutil.ReadFile(fmt.Sprintf("%s%s", templateLocation, variablesInput))
	if err != nil {
		log.Fatal(err)
	}

	variablesReplaced := bytes.ReplaceAll(variableTemplate, []byte("PROJECT_NAME"), []byte("TEST_TEST"))

	err = ioutil.WriteFile(fmt.Sprintf("%s%s", templateLocation, variablesOutput), variablesReplaced, 0644)
	if err != nil {
		log.Fatal(err)
	}

	return nil
}

func preCheck(check map[string]interface{}, project map[string]interface{}) (string, error) {
	if check["log_text"] != nil {
		log.Printf(check["log_text"].(string))
	}

	output := ""

	if check["command"] != nil {
		command := check["command"].(string)
		if check["variables"] != nil {
			variables := check["variables"].(map[string]interface{})

			for i := 0; i < len(variables); i++ {
				iString := strconv.Itoa(i)
				variable := variables[iString].(string)

				if project[variable] != nil {
					value := strings.ReplaceAll(project[variable].(string), " ", "|||")
					command = strings.Replace(command, "%s", value, 1)
				}
			}
		}

		splitCommand := strings.Split(command, " ")

		for i, c := range splitCommand {
			splitCommand[i] = strings.ReplaceAll(c, "|||", " ")
		}

		comm := exec.Command(splitCommand[0], splitCommand[1:len(splitCommand)]...)

		stdoutStderr, err := comm.CombinedOutput()
		if err != nil {
			log.Fatal(err)
		}

		output = strings.ReplaceAll(string(stdoutStderr), "\n", "")
	}

	return output, nil
}

// func checkType(instanceType string, region string) error {
// 	log.Printf("Checking availability of Instance Type in target region")
// 	filterOption := fmt.Sprintf("Name=instance-type,Values=%s", instanceType)

// 	comm := exec.Command("aws",
// 		"ec2",
// 		"describe-instance-type-offerings",
// 		"--location-type",
// 		"availability-zone",
// 		"--filters",
// 		filterOption,
// 		"--region",
// 		region,
// 		"--output",
// 		"json")

// 	stdoutStderr, err := comm.CombinedOutput()
// 	if err != nil {
// 		log.Fatal(err)
// 	}
// 	fmt.Printf("%s\n", stdoutStderr)

// 	return nil
// }

// func checkImage(imageName string, region string) (string, error) {
// 	filterOption := fmt.Sprintf(`Name=name,Values="%s"`, imageName)
// 	query := fmt.Sprintf(`sort_by(Images, &Name)[-1].ImageId`)

// 	comm := exec.Command("aws",
// 		"ec2",
// 		"describe-images",
// 		"--filters",
// 		filterOption,
// 		"--query",
// 		query,
// 		"--region",
// 		region,
// 		"--output",
// 		"text")

// 	fmt.Println(comm.Args)

// 	stdoutStderr, err := comm.CombinedOutput()
// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	fmt.Printf("%s\n", stdoutStderr)
// 	strippedT := strings.ReplaceAll(string(stdoutStderr), "\n", "")
// 	fmt.Println(strippedT)

// 	return string(strippedT), nil
// }

func terraformWorkspace(projectName string) error {
	log.Printf("Checking Projects in terraform")
	comm := exec.Command("terraform", "workspace", "list")
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	workspaceFound := false
	test := strings.Split(string(stdoutStderr), "\n")

	for _, t := range test {
		strippedT := strings.ReplaceAll(t, " ", "")
		strippedT = strings.ReplaceAll(strippedT, "*", "")
		if strippedT == projectName {
			workspaceFound = true
		}
	}

	if workspaceFound {
		comm = exec.Command("terraform", "workspace", "select", projectName)
		comm.Dir = templateLocation

		stdoutStderr, err := comm.CombinedOutput()
		if err != nil {
			log.Fatal(err)
		}

		fmt.Printf("%s\n", stdoutStderr)
	} else {
		comm = exec.Command("terraform", "workspace", "new", projectName)
		comm.Dir = templateLocation

		stdoutStderr, err := comm.CombinedOutput()
		if err != nil {
			log.Fatal(err)
		}

		fmt.Printf("%s\n", stdoutStderr)
	}

	return nil
}

func terraformApply(os string, ami string, region string, instanceCount string, ssh string, projectName string, pem string) error {
	arguments := []string{}

	arguments = append(arguments, "apply")
	arguments = append(arguments, "-auto-approve")
	arguments = append(arguments, fmt.Sprintf(`-var=os=%s`, os))
	arguments = append(arguments, fmt.Sprintf(`-var=ami_id=%s`, ami))
	arguments = append(arguments, fmt.Sprintf(`-var=aws_region=%s`, region))
	arguments = append(arguments, fmt.Sprintf(`-var=instance_count=%s`, instanceCount))
	arguments = append(arguments, fmt.Sprintf(`-var=ssh_key_path=%s`, ssh))
	arguments = append(arguments, fmt.Sprintf(`-var=cluster_name=%s`, projectName))
	arguments = append(arguments, fmt.Sprintf(`-var=pem_instance_count=%s`, pem))

	comm := exec.Command("terraform", arguments...)
	comm.Dir = templateLocation

	fmt.Println(comm.Args)

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}

func checkInstanceStatus(region string) error {
	cmd := exec.Command("aws", "ec2", "wait", "instance-status-ok", "--region", region)

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}
