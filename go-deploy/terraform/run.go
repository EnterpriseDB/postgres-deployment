package terraform

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strings"
)

func RunTerraform(project map[string]interface{}) error {
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	fmt.Println(project)

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, "terraform")
	splitPath = append(splitPath, "aws")

	joinedPath := strings.Join(splitPath, "/")

	tagsInput := "/tags.tf.template"
	tagsOutput := "/tags.tf"

	variablesInput := "/variables.tf.template"
	variablesOutput := "/variables.tf"

	tagTemplate, err := ioutil.ReadFile(fmt.Sprintf("%s%s", joinedPath, tagsInput))
	if err != nil {
		log.Fatal(err)
	}

	tagsReplaced := bytes.ReplaceAll(tagTemplate, []byte("PROJECT_NAME"), []byte("TEST_TEST"))

	err = ioutil.WriteFile(fmt.Sprintf("%s%s", joinedPath, tagsOutput), tagsReplaced, 0644)
	if err != nil {
		log.Fatal(err)
	}

	variableTemplate, err := ioutil.ReadFile(fmt.Sprintf("%s%s", joinedPath, variablesInput))
	if err != nil {
		log.Fatal(err)
	}

	variablesReplaced := bytes.ReplaceAll(variableTemplate, []byte("PROJECT_NAME"), []byte("TEST_TEST"))

	err = ioutil.WriteFile(fmt.Sprintf("%s%s", joinedPath, variablesOutput), variablesReplaced, 0644)
	if err != nil {
		log.Fatal(err)
	}

	os := "CentOS Linux 7 x86_64 HVM EBS*"
	region := "us-east-2"
	instanceCount := "1"
	ssh := "~/.ssh/id_rsa.pub"
	projectName := "test1"
	pem := "0"

	// checkType("c5.2xlarge", region)
	ami, err := checkImage("CentOS Linux 7 x86_64 HVM EBS*", region)
	terraformWorkspace(projectName, joinedPath)

	cmd := exec.Command("terraform", "init")
	fmt.Println(joinedPath)
	cmd.Dir = joinedPath

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)
		log.Fatal(err)
	}

	terraformApply(os, ami, region, instanceCount, ssh, projectName, pem, joinedPath)
	checkInstanceStatus(region)

	fmt.Printf("%s\n", stdoutStderr)
	// err = cmd.Run()
	// log.Printf("Command finished with error: %v", err)

	return nil
}

func checkType(instanceType string, region string) error {
	log.Printf("Checking availability of Instance Type in target region")
	filterOption := fmt.Sprintf("Name=instance-type,Values=%s", instanceType)

	comm := exec.Command("aws",
		"ec2",
		"describe-instance-type-offerings",
		"--location-type",
		"availability-zone",
		"--filters",
		filterOption,
		"--region",
		region,
		"--output",
		"json")

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%s\n", stdoutStderr)

	return nil
}

func checkImage(imageName string, region string) (string, error) {
	filterOption := fmt.Sprintf(`Name=name,Values="%s"`, imageName)
	query := fmt.Sprintf(`sort_by(Images, &Name)[-1].ImageId`)

	comm := exec.Command("aws",
		"ec2",
		"describe-images",
		"--filters",
		filterOption,
		"--query",
		query,
		"--region",
		region,
		"--output",
		"text")

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)
	strippedT := strings.ReplaceAll(string(stdoutStderr), "\n", "")
	fmt.Println(strippedT)

	return string(strippedT), nil
}

func terraformWorkspace(projectName string, joinedPath string) error {
	log.Printf("Checking Projects in terraform")
	comm := exec.Command("terraform", "workspace", "list")
	comm.Dir = joinedPath

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
		comm.Dir = joinedPath

		stdoutStderr, err := comm.CombinedOutput()
		if err != nil {
			log.Fatal(err)
		}

		fmt.Printf("%s\n", stdoutStderr)
	} else {
		comm = exec.Command("terraform", "workspace", "new", projectName)
		comm.Dir = joinedPath

		stdoutStderr, err := comm.CombinedOutput()
		if err != nil {
			log.Fatal(err)
		}

		fmt.Printf("%s\n", stdoutStderr)
	}

	return nil
}

func terraformApply(os string, ami string, region string, instanceCount string, ssh string, projectName string, pem string, joinedPath string) error {
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
	comm.Dir = joinedPath

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
