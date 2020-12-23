package terraform

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

var hardCodedPath = ""
var projectPrefixName = "projects"

func getProjectPath(projectName string, fileName string) string {
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, projectPrefixName)
	splitPath = append(splitPath, fileName)
	splitPath = append(splitPath, projectName)

	projectPath := strings.Join(splitPath, "/")

	return projectPath
}

func RunAnsible(projectName string,
	project map[string]interface{},
	arguements map[string]interface{},
	variables map[string]interface{},
	fileName string,
	customTemplateLocation *string,
) error {
	projectPath := getProjectPath(projectName, fileName)

	setHardCodedVariables(project, variables)
	setMappedVariables(project, variables)

	passPath := fmt.Sprintf("%s/.edbpass", projectPath)

	project["pass_dir"] = passPath

	args := []string{"collection", "install", "edb_devops.edb_postgres", "--force"}

	comm := exec.Command("ansible-galaxy", args...)
	comm.Dir = projectPath

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)

	}

	fmt.Printf("%s\n", stdoutStderr)

	ansibleRun := arguements["ansible_run"].(map[string]interface{})
	extraVariableSlice := ansibleRun["extra_variables"].([]interface{})
	variableSlice := ansibleRun["variables"].([]interface{})

	ansibleExtraVars := ""

	for _, arg := range extraVariableSlice {
		argMap := arg.(map[string]interface{})
		value := ""

		if project[argMap["variable"].(string)] != nil {
			value = project[argMap["variable"].(string)].(string)
		} else if argMap["default"] != nil {
			value = argMap["default"].(string)
		}

		ansibleExtraVars = fmt.Sprintf("%s%s=%s ", ansibleExtraVars, argMap["prefix"], value)
	}

	project["extra_vars"] = ansibleExtraVars

	args = []string{"--ssh-common-args=-o StrictHostKeyChecking=no"}

	for _, arg := range variableSlice {
		argMap := arg.(map[string]interface{})
		value := ""
		a := ""

		if project[argMap["variable"].(string)] != nil {
			value = project[argMap["variable"].(string)].(string)
		} else if argMap["default"] != nil {
			value = argMap["default"].(string)
		}

		if argMap["prefix"] != nil {
			a = fmt.Sprintf("--%s=%s", argMap["prefix"], value)
		} else {
			a = value
		}

		args = append(args, a)
	}

	comm = exec.Command("ansible-playbook", args...)
	comm.Dir = projectPath

	stdoutStderr, err = comm.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}
