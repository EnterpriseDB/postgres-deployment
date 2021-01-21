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

// Common Functions across Application
package cmd

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
)

var projectPrefixName = "projects"
var flowVariables = map[string]*string{}
var values = map[string]interface{}{}
var cloudName = ""
var projectName = ""

// var variables = map[string]interface{}{}
var encryptedValues = map[string]string{}

// Gets Project Path
func getProjectPath() (string, string) {
	path, err := os.Getwd()
	shared.CheckForErrors(err)

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, projectPrefixName)
	splitPath = append(splitPath, cloudName)
	rootPath := strings.Join(splitPath, "/")
	splitPath = append(splitPath, projectName)
	projectPath := strings.Join(splitPath, "/")

	if verbose {
		fmt.Println("--- Debugging:")
		fmt.Println("cloudName")
		fmt.Println(cloudName)
		fmt.Println("projectPrefixName")
		fmt.Println(projectPrefixName)
		fmt.Println("projectPath")
		fmt.Println(projectPath)
		fmt.Println("---")
	}

	logWrapper.Println("Completed 'getProjectPath'")
	return rootPath, projectPath
}

// Gets Terraform Path
func getTerraformPath(cloudName string) string {
	path, err := os.Getwd()
	shared.CheckForErrors(err)

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, "terraform")
	splitPath = append(splitPath, cloudName)
	terraformPath := strings.Join(splitPath, "/")

	logWrapper.Println("Completed 'getTerraformPath'")
	return terraformPath
}

// Gets Ansible Playbook Path
func getPlaybookPath() string {
	path, err := os.Getwd()
	shared.CheckForErrors(err)

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, "playbook")
	playbookPath := strings.Join(splitPath, "/")

	logWrapper.Println("Completed 'getPlaybookPath'")
	return playbookPath
}

// Returns credentials
func getCredentials() credentials {
	shared.CheckForEdbPath()
	content, err := ioutil.ReadFile(credFile)
	fmt.Println(credFile)
	if err != nil {
		fmt.Println("13")
		shared.CheckForErrors(err)
		logWrapper.Fatal(err)
	}

	var creds = credentials{}
	_ = json.Unmarshal(content, &creds)

	logWrapper.Println("Completed 'getCredentials'")
	return creds
}

// Returns Project Configuration
func getProjectConfigurations() map[string]interface{} {
	content, err := ioutil.ReadFile(confFile)
	if err != nil {
		fmt.Println("27")
		shared.CheckForErrors(err)
		logWrapper.Fatal(err)
	}

	var configurations map[string]interface{}
	_ = json.Unmarshal(content, &configurations)

	logWrapper.Println("Completed 'getProjectConfigurations'")
	return configurations
}

// Returns a prefix with the Project Name
func prependProjectName(fileName string) string {
	logWrapper.Println("Prepended Project Name: ", projectName, " with: ", fileName)
	return fmt.Sprintf("%s_%s", projectName, fileName)
}

// Returns the Project Name with a suffix
func appendToProjectRoute(fileName string, projectPath string) string {
	logWrapper.Println("Appended Project Path: ", projectPath, " with: ", fileName)
	return fmt.Sprintf("%s/%s", projectPath, fileName)
}
