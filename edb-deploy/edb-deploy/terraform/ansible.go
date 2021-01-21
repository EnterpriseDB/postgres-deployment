// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Original Author : https://www.rocketinsights.com/
// Date            : December 7, 2020
// Modifications, Updates and Additions:
// Re-architected, Re-factored, Re-Organized,
// Multi-Cloud Support,
// Logging, Error Handling
// By Contributor  : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

// Ansible Helper Functions
package terraform

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	// ansibler "github.com/apenella/go-ansible"
)

var hardCodedPath = ""
var projectPrefixName = "projects"
var inventoryYamlFileName = "inventory.yml"
var clusterProjectDetailsFile = "projectdetails.txt"
var pgPasswordFileName = "postgres_pass"
var epasPasswordFileName = "enterprisedb_pass"
var pgTypeText = "pg_type"
var osText = "operating_system"

var verbose bool = false

type CustomExecutor struct {
	Command string
	Args    []string
	Prefix  string
}

func (e *CustomExecutor) Execute(command string,
	args []string, prefix string) error {
	if verbose {
		logWrapper.Debug("---Debugging: terraform -> ansible.go -> Custom Executor:")
		logWrapper.Debug("args")
		logWrapper.Debug(args)
	}
	cmdPlaybook := exec.Command("ansible-playbook", args...)
	// cmdPlaybook.Dir = projectPath

	// cmdPlaybook := exec.Command("ansible-playbook", args...)
	// cmdPlaybook.Dir = projectPath

	stdoutStderr, _ := cmdPlaybook.CombinedOutput()
	// if err != nil {
	fmt.Printf("%s\n", stdoutStderr)
	// 	log.Fatal(err)
	// }
	fmt.Printf("%s\n", stdoutStderr)
	// shared.CheckForErrors(err)
	return nil
}

func getPlaybookCmdOptions(args []string, projectPath string) map[string]interface{} {
	playArgs := map[string]interface{}{
		"yum_username": "",
		"yum_password": "",
		// "pass_dir":     "",
		"private-key": "",
	}

	arrIndexValue := ""
	for index := range args {
		if verbose {
			logWrapper.Debug("Index:" + strconv.Itoa(index) + " value: " + args[index])
		}

		arrIndexValue = args[index]
		customValue := ""
		// switch arrIndexValue {
		if strings.Contains(arrIndexValue, "private-key") == true {
			playArgs["private-key"] = strings.ReplaceAll(args[index], "--private-key", "")
		}
		// if strings.Contains(arrIndexValue, "playbook") == true {
		// 	playArgs["playbook"] = projectPath + args[index]
		// }
		if strings.Contains(arrIndexValue, "inventory") == true {
			// invValue := ""
			// customValue = strings.ReplaceAll(args[index], "-i", "")
			playArgs["inventory"] = args[index]
		}
		if strings.Contains(arrIndexValue, "private-key") == true {
			customValue = strings.ReplaceAll(args[index], "--private-key=", "")
			playArgs["private-key"] = customValue
		}
		if strings.Contains(arrIndexValue, "extra") == true {
			extrasValue := strings.Split(args[index], " ")
			for extrasIndex := range extrasValue {
				extrasIndexValue := extrasValue[extrasIndex]
				// if strings.Contains(extrasIndexValue, "pass") == true {
				// 	playArgs["pass_dir"] = strings.ReplaceAll(extrasIndexValue,
				// 		"pass_dir=", "")
				// }
				if strings.Contains(extrasIndexValue, "pg_type") == true {
					extrasIndexValue = strings.ReplaceAll(extrasIndexValue, "--extra-vars='", "")
					playArgs["pg_type"] = strings.ReplaceAll(extrasIndexValue,
						"pg_type=", "")
				}
				if strings.Contains(extrasIndexValue, "pg_version") == true {
					playArgs["pg_version"] = strings.ReplaceAll(extrasIndexValue,
						"pg_version=", "")
				}
				if strings.Contains(extrasIndexValue, "yum_username") == true {
					playArgs["yum_username"] = strings.ReplaceAll(extrasIndexValue,
						"yum_username=", "")
				}
				if strings.Contains(extrasIndexValue, "yum_password") == true {
					playArgs["yum_password"] = strings.ReplaceAll(extrasIndexValue,
						"yum_password=", "")
				}
			}
		}
	}

	if verbose {
		logWrapper.Debug("playArgs")
		logWrapper.Debug(playArgs)
	}

	return playArgs
}

// Executes Ansible
func RunAnsible(projectName string,
	project map[string]interface{},
	arguements map[string]interface{},
	variables map[string]interface{},
	fileName string,
	customTemplateLocation *string,
) error {
	// Retrieve from Environment variable debugging setting
	verbose = shared.GetDebuggingStateFromOS()

	projectPath := getProjectPath(projectName, fileName) + "/"

	if verbose {
		logWrapper.Debug("--- Debugging - terraform/ansible.go - RunAnsible :")
		logWrapper.Debug("ProjectName")
		logWrapper.Debug(projectName)
		logWrapper.Debug("project")
		logWrapper.Debug(project)
		logWrapper.Debug("arguments")
		logWrapper.Debug(arguements)
		logWrapper.Debug("variables")
		logWrapper.Debug(variables)
		logWrapper.Debug("fileName")
		logWrapper.Debug(fileName)
		logWrapper.Debug("---")
	}

	setHardCodedVariables(project, variables)
	setMappedVariables(project, variables)

	// Sets the password directory to be under the project folder
	passPath := fmt.Sprintf("%s.edbpass", projectPath)
	passPath = strings.ReplaceAll(passPath, " ", "")
	// Check for existence of 'edbpass' folder
	shared.CheckFolderPath(passPath)
	// Sets password directory to be under the home directory
	// home, homeErr := homedir.Dir()
	// shared.CheckForErrors(homeErr)
	// passPath := fmt.Sprintf("%s/%s", home, ".edb")
	// passPath = strings.ReplaceAll(passPath, " ", "")

	project["pass_dir"] = passPath

	args := []string{"collection", "install", "edb_devops.edb_postgres", "--force"}
	cmdGalaxy := exec.Command("ansible-galaxy", args...)
	cmdGalaxy.Dir = projectPath

	stdoutStdGalaxyErr, galaxyErr := cmdGalaxy.CombinedOutput()
	shared.CheckForErrors(galaxyErr)
	fmt.Printf("%s\n", stdoutStdGalaxyErr)
	fmt.Printf("%s\n", galaxyErr)

	ansibleRun := arguements["ansible_run"].(map[string]interface{})
	extraVariableSlice := ansibleRun["extra_variables"].([]interface{})
	variableSlice := ansibleRun["variables"].([]interface{})

	ansibleExtraVars := ""

	for _, arg := range extraVariableSlice {
		argMap := arg.(map[string]interface{})
		value := ""

		if verbose {
			logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd - extraVariables:")
			logWrapper.Debug("extraVariableSlice")
			logWrapper.Debug(extraVariableSlice)
			logWrapper.Debug("variableSlice")
			logWrapper.Debug(variableSlice)
			logWrapper.Debug("variable")
			logWrapper.Debug(project[argMap["variable"].(string)])
			logWrapper.Debug("value")
			logWrapper.Debug(project[argMap["variable"].(string)].(string))
		}

		value = project[argMap["variable"].(string)].(string)

		if verbose {
			logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd - extraVariables:")
			logWrapper.Debug("variable")
			logWrapper.Debug(project[argMap["variable"].(string)])
			logWrapper.Debug("value")
			logWrapper.Debug(value)
		}

		if project[argMap["variable"].(string)] != nil {
			value = project[argMap["variable"].(string)].(string)
		} else if argMap["default"] != nil {
			value = argMap["default"].(string)
		}

		if verbose {
			logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd - extraVariables - findValueContainedInSlice:")
			logWrapper.Debug("variable")
			logWrapper.Debug(project[argMap["variable"].(string)])
			logWrapper.Debug("Updated value")
			logWrapper.Debug(value)
		}

		ansibleExtraVars = fmt.Sprintf("%s%s=%s ", ansibleExtraVars,
			argMap["prefix"], value)
	}

	project["extra_vars"] = "'" + ansibleExtraVars + "'"

	if verbose {
		logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd - extra_vars:")
		logWrapper.Debug("extra-vars")
		logWrapper.Debug(project["extra_vars"])
		logWrapper.Debug("args")
		logWrapper.Debug(args)
	}

	// args = []string{"--ssh-common-args='-o StrictHostKeyChecking=no'"}
	args = []string{}

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

	if verbose {
		logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd - extra_vars:")
		logWrapper.Debug("extra-vars")
		logWrapper.Debug(project["extra_vars"])
		logWrapper.Debug("args")
		logWrapper.Debug(args)
	}

	playAnsible := exec.Command("ansible-playbook", args...)
	playAnsible.Dir = projectPath

	stdoutStderr, err := playAnsible.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)
		logWrapper.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	ansibleUser := ""
	pgType := ""

	for _, arg := range variableSlice {
		argMap := arg.(map[string]interface{})
		value := ""
		a := ""

		if project[argMap["variable"].(string)] != nil {
			value = project[argMap["variable"].(string)].(string)

			if verbose {
				fmt.Println("--- Debugging - terraform - ansible.go - installCmd :")
				fmt.Println("variable")
				fmt.Println(project[argMap["variable"].(string)])
				fmt.Println("value")
				fmt.Println(project[argMap["variable"].(string)].(string))
				logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd :")
				logWrapper.Debug("variable")
				logWrapper.Debug(project[argMap["variable"].(string)])
				logWrapper.Debug("value")
				logWrapper.Debug(project[argMap["variable"].(string)].(string))
			}

			if strings.Contains(value, pgTypeText) {
				splitValue := strings.Split(value, " ")
				for i := 0; i < len(splitValue); i++ {
					if strings.Contains(splitValue[i], pgTypeText) {
						pgType = splitValue[i]
						pgType = strings.ReplaceAll(pgType, pgTypeText+"=", "")
					}
				}
			}
		} else if argMap["default"] != nil {
			value = argMap["default"].(string)
		}

		if argMap["prefix"] != nil {
			switch argMap["prefix"] {
			case "i":
				a = fmt.Sprintf("-%s %s%s", argMap["prefix"], projectPath, value)
			case "user":
				// No longer needed
				a = fmt.Sprintf("--%s=%s", argMap["prefix"], value)
				ansibleUser = value
			default:
				a = fmt.Sprintf("--%s=%s", argMap["prefix"], value)
			}
		} else {
			a = value
		}

		args = append(args, a)
	}

	// Remove unneeded characters
	pgType = strings.ReplaceAll(pgType, "'", "")

	if verbose {
		logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd :")
		logWrapper.Debug("ProjectName")
		logWrapper.Debug(projectName)
		logWrapper.Debug("args")
		logWrapper.Debug(args)
		logWrapper.Debug("ansibleUser")
		logWrapper.Debug(ansibleUser)
		logWrapper.Debug("pgType")
		logWrapper.Debug(pgType)
		logWrapper.Debug("projectPath")
		logWrapper.Debug(projectPath)
		logWrapper.Debug("arguements")
		logWrapper.Debug(arguements)
		logWrapper.Debug("---")
	}

	// Converts the slice args into a string for sending to the command line
	// ansibleCommandLine := strings.Join(args, " ")
	// ansibleCommandLine = strings.ReplaceAll(ansibleCommandLine, " '", "")

	// ansiblePlaybookConnectionOptions := &ansibler.AnsiblePlaybookConnectionOptions{
	// 	User: ansibleUser,
	// }

	// playbkCmdOptions := getPlaybookCmdOptions(args, projectPath)
	// ansiblePlaybookOptions := &ansibler.AnsiblePlaybookOptions{
	// 	Inventory: projectPath + "inventory.yml",
	// 	ExtraVars: playbkCmdOptions,
	// }

	// // playCmdLineParams := " --ssh-common-args='-o StrictHostKeyChecking=no'"
	// playbook := &ansibler.AnsiblePlaybookCmd{
	// 	Playbook:          projectPath + "playbook.yml",
	// 	ConnectionOptions: ansiblePlaybookConnectionOptions,
	// 	Options:           ansiblePlaybookOptions,
	// 	ExecPrefix:        projectName,
	// 	Exec: &CustomExecutor{"ansible-playbook",
	// 		args, projectName},
	// }

	// err := playbook.Run()

	if verbose {
		logWrapper.Debug("--- Debugging - terraform - ansible.go - installCmd :")
		logWrapper.Debug("projectPath")
		logWrapper.Debug(projectPath)
		logWrapper.Debug("---")
	}

	if err == nil {
		createClusterDetailsFile(projectName, fileName,
			ansibleUser, pgType, passPath)

		logWrapper.Println("Completed 'RunAnsible'")
	}
	return nil
}
