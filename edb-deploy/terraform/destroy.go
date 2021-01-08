// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

// Package terraform
package terraform

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

// Prepares for a Terraform Destroy
func DestroyTerraform(projectName string, project map[string]interface{}, arguements map[string]interface{}, fileName string, customTemplateLocation *string) error {
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

	getTerraformWorkspace(projectName)

	if arguements["terraform_destroy"] != nil {
		terrDestroy := arguements["terraform_destroy"].(map[string]interface{})
		argSlice := terrDestroy["variables"].([]interface{})
		terraformDestroy(argSlice, project)
	}

	return nil
}

// Retrieves current Terraform Workspace
func getTerraformWorkspace(projectName string) error {
	log.Printf("Checking Projects in terraform")

	comm := exec.Command("terraform", "workspace", "select", projectName)
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}

// Executes a Terraform Destroy
func terraformDestroy(argSlice []interface{}, project map[string]interface{}) error {
	log.Printf("Checking Projects in terraform")

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
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}

// Deletes a Terraform Workspace
func deleteTerraformWorkspace(projectName string) error {
	log.Printf("Checking Projects in terraform")

	comm := exec.Command("terraform", "workspace", "select", "default")
	comm.Dir = templateLocation

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	comm = exec.Command("terraform", "workspace", "delete", projectName)
	comm.Dir = templateLocation

	stdoutStderr, err = comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}
