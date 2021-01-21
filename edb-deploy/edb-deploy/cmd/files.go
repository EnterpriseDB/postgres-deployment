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

// Project Functions
package cmd

import (
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
)

// Copies a Files
func fileCopy(sourceFile string, destinationPath string, destinationFile string) {
	input, err := ioutil.ReadFile(sourceFile)
	if err != nil {
		shared.CheckForErrors(err)
		return
	}

	if _, err := os.Stat(destinationPath); os.IsNotExist(err) {
		os.MkdirAll(destinationPath, os.ModePerm)
	}

	err = ioutil.WriteFile(destinationFile, input, 0744)
	if err != nil {
		fmt.Println("Error creating", destinationFile)
		shared.CheckForErrors(err)
		return
	}
}

// Removes Empty Lines and Spaces from a File
func removeEmptyLinesAndSpaces(fileNameAndPath string) error {
	file, err := ioutil.ReadFile(fileNameAndPath)
	shared.CheckForErrors(err)

	strFileContent := regexp.MustCompile(`[\t\r\n]+`).ReplaceAllString(strings.TrimSpace(string(file)), "\n")
	re := regexp.MustCompile("(?m)^\\s*$[\r\n]*")
	strFileContent = strings.Trim(re.ReplaceAllString(strFileContent, ""), "\r\n")
	err = ioutil.WriteFile(fileNameAndPath, []byte(strFileContent), 0644)

	shared.CheckForErrors(err)
	return nil
}

// Checks for File Existence
func fileExists(fileNameAndPath string) bool {
	info, err := os.Stat(fileNameAndPath)
	shared.CheckForErrors(err)
	if os.IsNotExist(err) {
		return false
	}

	return !info.IsDir()
}

// Changes Permissions for a File
func chmodFilePermissions(fileNameAndPath string) error {
	fileStats, err := os.Stat(fileNameAndPath)
	if verbose {
		fmt.Printf("File Permission before change: %s\n", fileStats.Mode())

	}
	// Set the File permissions to a more moderate setting
	err = os.Chmod(fileNameAndPath, 0600)
	if err != nil {
		return shared.CheckForErrors(err)
	}
	fileStats, err = os.Stat(fileNameAndPath)
	if verbose {
		fmt.Printf("File Permission after change: %s\n", fileStats.Mode())
	}

	return nil
}

// Copies Multiples Files
func copyFiles(fileName string) error {
	tPath := getTerraformPath(fileName)
	pPath := getPlaybookPath()
	_, projectPath := getProjectPath()

	ansInputConf := fmt.Sprintf("%s/ansible.cfg", pPath)
	ansOutputConf := fmt.Sprintf("%s/ansible.cfg", projectPath)
	fileCopy(ansInputConf, projectPath, ansOutputConf)

	psiInputConf := fmt.Sprintf("%s/playbook-single-instance.yml", pPath)
	psiOutputConf := fmt.Sprintf("%s/playbook-single-instance.yml", projectPath)
	fileCopy(psiInputConf, projectPath, psiOutputConf)

	pInputConf := fmt.Sprintf("%s/playbook.yml", pPath)
	pOutputConf := fmt.Sprintf("%s/playbook.yml", projectPath)
	fileCopy(pInputConf, projectPath, pOutputConf)

	rfrInputConf := fmt.Sprintf("%s/rhel_firewald_rule.yml", pPath)
	rfrOutputConf := fmt.Sprintf("%s/rhel_firewald_rule.yml", projectPath)
	fileCopy(rfrInputConf, projectPath, rfrOutputConf)

	hInputConf := fmt.Sprintf("%s/pem-inventory.yml", tPath)
	hOutputConf := fmt.Sprintf("%s/hosts.yml", projectPath)
	fileCopy(hInputConf, projectPath, hOutputConf)

	pemInputConf := fmt.Sprintf("%s/pem-inventory.yml", tPath)
	pemOutputConf := fmt.Sprintf("%s/pem-inventory.yml", projectPath)
	if verbose {
		fmt.Println("--- Debugging - project.go - copyFiles:")
		fmt.Println("projectPath")
		fmt.Println(projectPath)
		fmt.Println("pemOutputConf")
		fmt.Println(pemOutputConf)
	}
	fileCopy(pemInputConf, projectPath, pemOutputConf)
	removeEmptyLinesAndSpaces(pemOutputConf)

	iInputConf := fmt.Sprintf("%s/inventory.yml", tPath)
	iOutputConf := fmt.Sprintf("%s/inventory.yml", projectPath)
	if verbose {
		fmt.Println("--- Debugging - project.go - copyFiles:")
		fmt.Println("projectPath")
		fmt.Println(projectPath)
		fmt.Println("iOutputConf")
		fmt.Println(iOutputConf)
	}
	fileCopy(iInputConf, projectPath, iOutputConf)
	removeEmptyLinesAndSpaces(iOutputConf)

	oInputConf := fmt.Sprintf("%s/os.csv", tPath)
	oOutputConf := fmt.Sprintf("%s/os.csv", projectPath)
	fileCopy(oInputConf, projectPath, oOutputConf)

	aInputConf := fmt.Sprintf("%s/add_host.sh", tPath)
	aOutputConf := fmt.Sprintf("%s/add_host.sh", projectPath)
	fileCopy(aInputConf, projectPath, aOutputConf)

	return nil
}

// Retrieves the FileName
func getFileName(route string) string {
	splitRoute := strings.Split(route, "/")

	return splitRoute[len(splitRoute)-1]
}
