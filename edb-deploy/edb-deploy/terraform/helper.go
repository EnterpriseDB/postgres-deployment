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

// Package terraform
// Contains code for terraform
package terraform

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
)

var templateLocation = ""

// RunTerraform
// Calls Terraform
func RunTerraform(projectName string, project map[string]interface{}, arguements map[string]interface{}, variables map[string]interface{}, fileName string, customTemplateLocation *string) error {
	// Retrieve from Environment variable debugging setting
	verbose = shared.GetDebuggingStateFromOS()

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Starting...")
		logWrapper.Debug("---")
	}

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
		splitPath = append(splitPath, fileName)

		templateLocation = strings.Join(splitPath, "/")
	}

	project["project_name"] = projectName

	setHardCodedVariables(project, variables)
	setMappedVariables(project, variables)
	setVariableAndTagNames(projectName)

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Calling: 'pre_run_checks'...")
		logWrapper.Debug("project")
		logWrapper.Debug(project)
		logWrapper.Debug("projectName")
		logWrapper.Debug(projectName)
		logWrapper.Debug("---")
	}

	// if arguements["pre_run_checks"] != nil {
	// 	preRunChecks := arguements["pre_run_checks"].(map[string]interface{})

	// 	if verbose {
	// 		fmt.Println("--- Debugging - terraform -> run.go - RunTerraform:")
	// 		fmt.Println("preRunChecks")
	// 		fmt.Println(preRunChecks)
	// 		fmt.Println("len of preRunChecks")
	// 		fmt.Println(len(preRunChecks))
	// 		fmt.Println("---")
	// 	}

	// 	for i := 0; i < len(preRunChecks); i++ {
	// 		iString := strconv.Itoa(i)

	// 		if verbose {
	// 			fmt.Println("iString")
	// 			fmt.Println(iString)
	// 		}

	// 		check := preRunChecks[iString].(map[string]interface{})

	// 		if verbose {
	// 			fmt.Println("check")
	// 			fmt.Println(check)
	// 		}

	// 		output, _ := preCheck(check, project)

	// 		if verbose {
	// 			fmt.Println("project")
	// 			fmt.Println(project)
	// 			fmt.Println("output")
	// 			fmt.Println(output)
	// 		}

	// 		if check["output"] != nil {
	// 			project[check["output"].(string)] = output
	// 		}
	// 	}
	// }

	preChecksPassed := false

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Calling: 'Pre-Checks'...")
		logWrapper.Debug("Cloud:")
		logWrapper.Debug(fileName)
		logWrapper.Debug("preChecksPassed:")
		logWrapper.Debug(preChecksPassed)
		logWrapper.Debug("---")
	}

	// Pre-Checks for each cloud
	foundAwsAMI := false
	amiID := ""
	switch fileName {
	case "aws":
		foundAwsAMI, amiID = listAwsInstanceAmiIDs(false, fmt.Sprintf("%v", project["region"]),
			fmt.Sprintf("%v", project["operating_system"]))
		foundAwsInstanceType := listAwsInstanceTypeOfferings(fmt.Sprintf("%v", project["instance_type"]),
			false, fmt.Sprintf("%v", project["region"]))
		if foundAwsInstanceType && foundAwsAMI {
			preChecksPassed = true
		}
	}
	project["ami_id"] = amiID

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Called: 'Pre-Checks'...")
		logWrapper.Debug("Cloud:")
		logWrapper.Debug(fileName)
		logWrapper.Debug("preChecksPassed:")
		logWrapper.Debug(preChecksPassed)
		logWrapper.Debug("---")
	}

	if preChecksPassed != true {
		logWrapper.Println("Pre-Checks did not pass!")
		logWrapper.Println("Please check if: Instance Type or AMI exist in AWS Region")
	}

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Returned from Calling: 'pre_run_checks'...")
		logWrapper.Debug("---")
	}

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Calling: 'terraformWorkspace'...")
		logWrapper.Debug("project")
		logWrapper.Debug(project)
		logWrapper.Debug("projectName")
		logWrapper.Debug(projectName)
		logWrapper.Debug("templateLocation")
		logWrapper.Debug(templateLocation)
		logWrapper.Debug("---")
	}

	err := terraformWorkspace(projectName)
	shared.CheckForErrors(err)

	cmd := exec.Command("terraform", "init")
	cmd.Dir = templateLocation

	_, err = cmd.CombinedOutput()
	shared.CheckForErrors(err)

	if arguements["terraform_build"] != nil {

		terraformBuild := arguements["terraform_build"].(map[string]interface{})
		argSlice := terraformBuild["variables"].([]interface{})

		if verbose {
			logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
			logWrapper.Debug("Preparing: 'terraform_build'...")
			logWrapper.Debug("project")
			logWrapper.Debug(project)
			logWrapper.Debug("terraformBuild")
			logWrapper.Debug(terraformBuild)
			logWrapper.Debug("argSlice")
			logWrapper.Debug(argSlice)
			logWrapper.Debug("---")
		}

		terraformApply(argSlice, project)
	}

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Called: 'terraform_build'...")
		logWrapper.Debug("---")
	}

	// Post-Checks for each cloud
	switch fileName {
	case "aws":
		time.Sleep(15 * time.Second)
	default:
		time.Sleep(15 * time.Second)
	}

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> run.go - RunTerraform:")
		logWrapper.Debug("Leaving...")
		logWrapper.Debug("---")
	}

	return nil
}

// Manages Terraform workspaces
func terraformWorkspace(projectName string) error {
	fmt.Println("Checking Projects in terraform")
	logWrapper.Println("Checking Projects in terraform")

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> helper.go - terraformWorkspace:")
		logWrapper.Debug("Calling: 'terraform workspace list'...")
		logWrapper.Debug("templateLocation")
		logWrapper.Debug(templateLocation)
		logWrapper.Debug("---")
	}

	comm := exec.Command("terraform", "workspace", "list")
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	// shared.CheckForErrors(err)
	if err != nil {
		// log.Fatal(err)
		// return
	}

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> helper.go - terraformWorkspace:")
		logWrapper.Debug("Returned from Calling: 'terraform workspace list'...")
		logWrapper.Debug("---")
	}

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> helper.go - terraformWorkspace:")
		logWrapper.Debug("Preparing: 'terraform workspace select'...")
		logWrapper.Debug("---")
	}

	workspaceFound := false
	test := strings.Split(string(stdoutStderr), "\n")

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> helper.go - terraformWorkspace:")
		logWrapper.Debug("Preparing: 'terraform workspace iterate'...")
		logWrapper.Debug("test")
		logWrapper.Debug(test)
		logWrapper.Debug("---")
	}

	for _, t := range test {
		strippedT := strings.ReplaceAll(t, " ", "")
		strippedT = strings.ReplaceAll(strippedT, "*", "")
		if strippedT == projectName {
			workspaceFound = true
		}
	}

	if workspaceFound {
		if verbose {
			logWrapper.Debug("--- Debugging - terraform -> helper.go - terraformWorkspace:")
			logWrapper.Debug("Workspace found...")
			logWrapper.Debug("projectName")
			logWrapper.Debug(projectName)
			logWrapper.Debug("templateLocation")
			logWrapper.Debug(templateLocation)
			logWrapper.Debug("---")
		}

		comm = exec.Command("terraform", "workspace", "select", projectName)
		comm.Dir = templateLocation

		stdoutStderr, err := comm.CombinedOutput()
		// shared.CheckForErrors(err)
		if err != nil {
			// log.Fatal(err)
			// return
		}

		fmt.Printf("%s\n", stdoutStderr)
	} else {
		if verbose {
			logWrapper.Debug("--- Debugging - terraform -> helper.go - terraformWorkspace:")
			logWrapper.Debug("Workspace not found...")
			logWrapper.Debug("projectName")
			logWrapper.Debug(projectName)
			logWrapper.Debug("templateLocation")
			logWrapper.Debug(templateLocation)
			logWrapper.Debug("---")
		}
		comm = exec.Command("terraform", "workspace", "new", projectName)
		comm.Dir = templateLocation

		stdoutStderr, err := comm.CombinedOutput()
		// shared.CheckForErrors(err)
		if err != nil {
			// log.Fatal(err)
			// return
		}

		fmt.Printf("%s\n", stdoutStderr)
	}

	if verbose {
		logWrapper.Debug("--- Debugging - terraform -> helper.go - terraformWorkspace:")
		logWrapper.Debug("Returned from Calling: 'terraform workspace select/new'...")
		logWrapper.Debug("---")
	}

	return nil
}

// Executes a Terraform Apply
func terraformApply(argSlice []interface{}, project map[string]interface{}) error {
	arguments := []string{}

	arguments = append(arguments, "apply")
	arguments = append(arguments, "-auto-approve")

	for _, arg := range argSlice {
		argMap := arg.(map[string]interface{})
		value := ""

		if project[argMap["variable"].(string)] != nil {
			value = project[argMap["variable"].(string)].(string)
		} else if argMap["default"] != nil {
			value = argMap["default"].(string)
		}
		a := fmt.Sprintf("-var=%s=%s", argMap["prefix"], value)

		arguments = append(arguments, a)
	}

	comm := exec.Command("terraform", arguments...)
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	shared.CheckForErrors(err)

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}
