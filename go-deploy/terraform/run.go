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

	// checkType("c5.2xlarge", "us-east-2")
	// checkImage("CentOS Linux 7 x86_64 HVM EBS*", "us-east-2")
	terraformWorkspace("test1", joinedPath)

	cmd := exec.Command("terraform", "init")
	fmt.Println(joinedPath)
	cmd.Dir = joinedPath

	log.Printf("Running command and waiting for it to finish...")

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)
		log.Fatal(err)
	}
	fmt.Printf("%s\n", stdoutStderr)
	err = cmd.Run()
	log.Printf("Command finished with error: %v", err)

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

func checkImage(imageName string, region string) error {
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

	return nil
}

func terraformWorkspace(projectName string, joinedPath string) error {
	log.Printf("Checking Projects in terraform")
	comm := exec.Command("terraform", "workspace", "list")
	comm.Dir = joinedPath

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

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
			fmt.Printf("%s\n", stdoutStderr)
			log.Fatal(err)
		}

		fmt.Printf("%s\n", stdoutStderr)
	} else {
		comm = exec.Command("terraform", "workspace", "new", projectName)
		comm.Dir = joinedPath

		stdoutStderr, err := comm.CombinedOutput()
		if err != nil {
			fmt.Printf("%s\n", stdoutStderr)
			log.Fatal(err)
		}

		fmt.Printf("%s\n", stdoutStderr)
	}

	return nil
}

// func terraformApply(os string, ami string, region string, instanceCount int, ssh string, projectName string, pem int) error {
// 	arguments := []string{}

// 	arguments = append(arguments, fmt.Sprintf(`-var="os=%s`, os))
// 	arguments = append(arguments, fmt.Sprintf(`-var="ami_id=%s`, os))
// 	arguments = append(arguments, fmt.Sprintf(`-var="aws_region=%s`, os))
// 	arguments = append(arguments, fmt.Sprintf(`-var="os=%s`, os))
// 	arguments = append(arguments, fmt.Sprintf(`-var="os=%s`, os))
// 	arguments = append(arguments, fmt.Sprintf(`-var="os=%s`, os))
// 	arguments = append(arguments, fmt.Sprintf(`-var="os=%s`, os))

// 	comm := exec.Command("terraform", "apply")

// 	return nil
// }
