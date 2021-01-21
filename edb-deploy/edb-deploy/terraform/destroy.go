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

// Terraform Destroy Helpers
package terraform

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
)

// Prepares for a Terraform Destroy
func DestroyTerraform(projectName string, project map[string]interface{}, arguements map[string]interface{}, fileName string, customTemplateLocation *string) error {
	if customTemplateLocation != nil {
		templateLocation = *customTemplateLocation
	} else {
		path, err := os.Getwd()
		shared.CheckForErrors(err)

		splitPath := strings.Split(path, "/")

		if len(splitPath) > 0 {
			splitPath = splitPath[:len(splitPath)-1]
		}

		splitPath = append(splitPath, "terraform")
		splitPath = append(splitPath, fileName)

		templateLocation = strings.Join(splitPath, "/")
	}

	getTerraformWorkspace(projectName)

	if arguements["terraform_destroy"] != nil {
		terrDestroy := arguements["terraform_destroy"].(map[string]interface{})
		argSlice := terrDestroy["variables"].([]interface{})
		terraformDestroy(argSlice, project)
		deleteTerraformWorkspace(projectName)
	}

	logWrapper.Println("Completed 'DestroyTerraform'")
	return nil
}

// Retrieves current Terraform Workspace
func getTerraformWorkspace(projectName string) error {
	fmt.Println("Checking Projects in terraform")
	logWrapper.Println("Checking Projects in terraform")

	comm := exec.Command("terraform", "workspace", "select", projectName)
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	shared.CheckForErrors(err)

	fmt.Printf("%s\n", stdoutStderr)

	logWrapper.Println("Completed 'getTerraformWorkspace'")
	return nil
}

// Executes a Terraform Destroy
func terraformDestroy(argSlice []interface{}, project map[string]interface{}) error {
	fmt.Println("Checking Projects in terraform")
	logWrapper.Println("Checking Projects in terraform")

	arguments := []string{}

	arguments = append(arguments, "destroy")
	arguments = append(arguments, "-auto-approve")

	for _, arg := range argSlice {
		argMap := arg.(map[string]interface{})
		a := fmt.Sprintf("-var=%s=%s", argMap["prefix"], project[argMap["variable"].(string)])

		arguments = append(arguments, a)
	}

	fmt.Println(arguments)

	comm := exec.Command("terraform", arguments...)
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	shared.CheckForErrors(err)

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}

// Deletes a Terraform Workspace
func deleteTerraformWorkspace(projectName string) error {
	fmt.Println("Checking Projects in terraform")
	logWrapper.Println("Checking Projects in terraform")

	comm := exec.Command("terraform", "workspace", "select", "default")
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	shared.CheckForErrors(err)

	comm = exec.Command("terraform", "workspace", "delete", projectName)
	comm.Dir = templateLocation

	stdoutStderr, err = comm.CombinedOutput()
	shared.CheckForErrors(err)

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}
