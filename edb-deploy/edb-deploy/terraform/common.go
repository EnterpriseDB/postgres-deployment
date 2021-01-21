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

// Common Terraform Functions
package terraform

import (
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/smallfish/simpleyaml"
)

// Parses OS Distributions
func formatOS(os string) string {
	str := os
	stripped := strings.Replace(str, "_", ".", -1)
	stripped = strings.Replace(str, "-", "", -1)
	parts := strings.Split(stripped, ".")
	stripped = parts[0]
	stripped = strings.Replace(stripped, "os", "OS", -1)
	stripped = strings.Replace(stripped, "rhel", "RHEL", -1)
	stripped = strings.Replace(stripped, "cent", "Cent", -1)

	logWrapper.Println("Completed 'formatOS'")
	return string(stripped)
}

// Iterates a Slice seeking for a string value
func findValueContainedInSlice(a []string, x string) (int, string) {
	for i, n := range a {
		if strings.Contains(n, x) {
			return i, n
		}
	}

	logWrapper.Println("Completed 'findValueContainedInSlice'")
	return len(a), ""
}

// Reads a File
func readFileContent(fileNameAndPath string) string {
	fileContent, err := ioutil.ReadFile(fileNameAndPath)
	shared.CheckForErrors(err)

	logWrapper.Println("Completed 'readFileContent'")
	return string(fileContent)
}

// Gets the Project Path
func getProjectPath(projectName string, fileName string) string {
	path, err := os.Getwd()
	shared.CheckForErrors(err)
	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, projectPrefixName)
	splitPath = append(splitPath, fileName)
	splitPath = append(splitPath, projectName)

	projectPath := strings.Join(splitPath, "/")

	logWrapper.Println("Completed 'getProjectPath'")
	return projectPath
}

// Creates a Text File with the Project Details
func createClusterDetailsFile(projectName string,
	fileName string,
	ansibleUser string,
	pgType string,
	passDir string) error {
	pgTypePassword := ""
	projectPath := getProjectPath(projectName, fileName)

	if verbose {
		fmt.Println("---")
		fmt.Println("--- Debugging: terraform - common.go")
		fmt.Println("pgType")
		fmt.Println(pgType)
		fmt.Println("pgType contains 'EPAS'")
		fmt.Println(strings.Contains(pgType, "EPAS"))
		fmt.Println("Pass Dir:")
		fmt.Println(passDir)
		fmt.Println("---")
	}

	if strings.Contains(pgType, "EPAS") == true {
		pgTypePassword = readFileContent(passDir + "/" + epasPasswordFileName)
	} else {
		pgTypePassword = readFileContent(passDir + "/" + pgPasswordFileName)
	}

	inventoryYamlFileName = projectPath + "/" + inventoryYamlFileName
	iYamlFile, err := ioutil.ReadFile(inventoryYamlFileName)
	shared.CheckForErrors(err)

	iyaml, err := simpleyaml.NewYaml(iYamlFile)
	shared.CheckForErrors(err)

	file, err := os.Create(projectPath + "/" + clusterProjectDetailsFile)
	shared.CheckForErrors(err)

	pemServerPublicIP, err := iyaml.GetPath("all", "children", "pemserver", "hosts", "pemserver1", "ansible_host").String()
	shared.CheckForErrors(err)

	if pemServerPublicIP != "" {
		fmt.Println("PEM SERVER:")
		file.WriteString("PEM SERVER:" + "\n")
		fmt.Println("-----------")
		file.WriteString("-----------" + "\n")
		fmt.Println("PEM URL: https://" + pemServerPublicIP + ":8443/pem")
		file.WriteString("PEM URL: https://" + pemServerPublicIP + ":8443/pem" + "\n")
	}

	if pgType == "EPAS" {
		fmt.Println("Username: enterprisedb")
		file.WriteString("Username: enterprisedb" + "\n")
		fmt.Println("Password: " + pgTypePassword)
		file.WriteString("Password: " + pgTypePassword + "\n")
	} else {
		fmt.Println("Username: postgres")
		file.WriteString("Username: postgres" + "\n")
		fmt.Println("Password: " + pgTypePassword)
		file.WriteString("Password: " + pgTypePassword + "\n")
	}

	primaryServers, err := iyaml.GetPath("all", "children", "primary", "hosts").GetMapKeys()
	shared.CheckForErrors(err)

	if verbose {
		fmt.Println("--- Debugging - terraform - ansible.go - createClusterFileDetails :")
		fmt.Println("Primary Server: ", primaryServers)
		fmt.Println("Primary Server Value:", primaryServers[0])
		fmt.Println("---")
	}

	sort.Strings(primaryServers)

	fmt.Println(" ")
	file.WriteString("\n")

	if len(primaryServers) > 0 {
		fmt.Println("PRIMARY SERVERS:")
		file.WriteString("PRIMARY SERVERS:" + "\n")
		fmt.Println("---------------")
		file.WriteString("---------------" + "\n")
		fmt.Println("Username: ", ansibleUser)
		file.WriteString("Username: " + ansibleUser + "\n")
		for i := 0; i < len(primaryServers); i++ {
			primaryServersIP, err := iyaml.GetPath("all", "children", "primary", "hosts", primaryServers[i], "ansible_host").String()
			fmt.Println("SERVER: ", primaryServers[i])
			file.WriteString("SERVER: " + primaryServers[i] + "\n")
			fmt.Println("Public IP: ", primaryServersIP)
			file.WriteString("Public IP: " + primaryServersIP + "\n")
			if err != nil {
				panic(err)
			}
		}
	}

	fmt.Println(" ")
	file.WriteString("\n")

	standbyServers, err := iyaml.GetPath("all", "children", "standby", "hosts").GetMapKeys()
	if verbose {
		fmt.Println("--- Debugging - terraform - ansible.go - createClusterFileDetails :")
		fmt.Println("Standby Servers: ", standbyServers)
		fmt.Println("---")
	}
	sort.Strings(standbyServers)

	if len(standbyServers) > 0 {
		fmt.Println("STANDBY SERVERS:")
		file.WriteString("STANDBY SERVERS:" + "\n")
		fmt.Println("---------------")
		file.WriteString("---------------" + "\n")
		fmt.Println("Username: ", ansibleUser)
		file.WriteString("Username: " + ansibleUser + "\n")
		for i := 0; i < len(standbyServers); i++ {
			secondaryServersIP, err := iyaml.GetPath("all", "children", "standby", "hosts", standbyServers[i], "ansible_host").String()
			fmt.Println("STANDBY SERVER: ", standbyServers[i])
			file.WriteString("STANDBY SERVER: " + standbyServers[i] + "\n")
			fmt.Println("Public IP: ", secondaryServersIP)
			file.WriteString("Public IP: " + secondaryServersIP + "\n")
			if err != nil {
				panic(err)
			}
		}
	}

	fmt.Println(" ")
	err = file.Close()
	shared.CheckForErrors(err)

	logWrapper.Println("Completed 'createClusterDetailsFile'")
	return nil
}
