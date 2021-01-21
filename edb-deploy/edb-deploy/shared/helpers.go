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

// Shared Helper Functions
package shared

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	homedir "github.com/mitchellh/go-homedir"
)

var verbose bool = false
var projectPrefixName = "projects"
var cloudName = ""
var projectName = ""

const edbPath = "/.edb"

// Retrieves the value for Debugging from OS
func GetDebuggingStateFromOS() bool {
	var debuggingState bool

	// Retrieve from Environment variable debugging setting
	verboseValue, verbosePresent := os.LookupEnv("DEBUG")
	if verbosePresent {
		verbose, _ = strconv.ParseBool(verboseValue)
		debuggingState = true
	} else {
		debuggingState = false
	}

	logWrapper.Println("Completed 'getDebuggingStateFromOS'")
	return debuggingState
}

// Gets Project Path
func getProjectPath() (string, string) {
	path, err := os.Getwd()
	CheckForErrors(err)

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

// Gets EDB Path
func CheckForEdbPath() {
	home, err := homedir.Dir()
	fullEdbPath := home + edbPath
	if err != nil {
		CheckForErrors(err)
		os.Exit(1)
	}

	if _, err := os.Stat(fullEdbPath); os.IsNotExist(err) {
		errEdbPath := os.Mkdir(fullEdbPath, os.ModePerm)
		CheckForErrors(errEdbPath)
	}

	logWrapper.Println("Verified existence of 'edbPath'")
}

// Gets Folder Path
func CheckFolderPath(folderPath string) {
	if _, err := os.Stat(folderPath); os.IsNotExist(err) {
		errFolderPath := os.Mkdir(folderPath, 0755)
		CheckForErrors(errFolderPath)
	}

	logWrapper.Println("Verified existence of '" + folderPath + "'")
}
