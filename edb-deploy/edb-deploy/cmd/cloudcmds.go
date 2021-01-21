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

// Terraform Functions
package cmd

import (
	"fmt"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/terraform"
	"github.com/spf13/cobra"
)

// Deploys ( Creates Infrastructure and Installs ) a Project via Terraform
func deployProjectCmd(commandName string,
	command map[string]interface{},
	fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			runProjectCmdCode(cmd, command, fileName)
			logWrapper.Println("Called the 'runProjectCmdCode'")
			installCmdCode(cmd, command, fileName)
			logWrapper.Println("Called the 'installCmdCode'")
		},
	}
	return cmd
}

// Creates Infrastructure with Terraform
func runProjectCmdCode(cmd *cobra.Command,
	command map[string]interface{},
	fileName string) {
	projectnameFlag, err := cmd.Flags().GetString(projectNameFlagValue)
	shared.CheckForErrors(err)

	if verbose {
		fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
		fmt.Println("Flags")
		fmt.Println("project-name")
		fmt.Println(projectnameFlag)
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("---")
	}

	if projectnameFlag == "" {
		handleInputValues(command, true, nil)
	} else {
		projectName = projectnameFlag
	}

	projectFound := false
	project := map[string]interface{}{}
	projectConfigurations := getProjectConfigurations()

	if verbose {
		fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
		fmt.Println("project")
		fmt.Println(project)
		fmt.Println("Project Configurations")
		fmt.Println(projectConfigurations)
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("---")
	}

	for pName, proj := range projectConfigurations {
		if pName == strings.ToLower(projectName) {
			projMap := proj.(map[string]interface{})
			for k, v := range projMap {
				project[k] = v
			}
			projectFound = true
		}
	}

	if !projectFound {
		fmt.Println("Project not found!")
		return
	}

	arguments := command["arguments"].(map[string]interface{})

	logWrapper.Println("Called 'terraform.RunTerraform'")
	errTerr := terraform.RunTerraform(strings.ToLower(projectName), project, arguments,
		variables, fileName, nil)
	shared.CheckForErrors(errTerr)
	logWrapper.Println("Completed 'terraform.RunTerraform'")

	copyFiles(fileName)
	logWrapper.Println("Copied files for: ", fileName)
}

// Configures Infrastructure via Ansible
func installCmdCode(cmd *cobra.Command,
	command map[string]interface{},
	fileName string) {
	projectnameFlag, err := cmd.Flags().GetString(projectNameFlagValue)
	shared.CheckForErrors(err)

	if projectnameFlag != "" && verbose {
		fmt.Println("--- Debugging - terraform.go - installCmdCode:")
		fmt.Println("Flags")
		fmt.Println("project-name")
		fmt.Println(projectnameFlag)
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("---")
	}

	if projectnameFlag == "" {
		handleInputValues(command, true, nil)
	} else {
		projectName = projectnameFlag
	}

	projectFound := false

	project := map[string]interface{}{}

	credentials := getCredentials()
	projectConfigurations := getProjectConfigurations()

	for pName, proj := range projectConfigurations {
		if pName == strings.ToLower(projectName) {
			projMap := proj.(map[string]interface{})
			for k, v := range projMap {
				project[k] = v
			}
			projectFound = true
		}
	}

	if !projectFound {
		fmt.Println("Project not found")
		return
	}

	arguments := command["arguments"].(map[string]interface{})

	if verbose {
		fmt.Println("--- Debugging - ansible.go - installCmd :")
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("project")
		fmt.Println(project)
		fmt.Println("arguments")
		fmt.Println(arguments)
		fmt.Println("variables")
		fmt.Println(variables)
		fmt.Println("fileName")
		fmt.Println(fileName)
		fmt.Println("---")
	}

	project["user_name"] = credentials.YumUserName
	project["password"] = credentials.YumPassword

	logWrapper.Println("Called 'terraform.RunAnsible'")
	errAns := terraform.RunAnsible(strings.ToLower(projectName), project,
		arguments, variables, fileName, nil)
	shared.CheckForErrors(errAns)
	logWrapper.Println("Completed 'terraform.RunAnsible'")
}

// Creates Infrastructure with Terraform
func runProjectCmd(commandName string,
	command map[string]interface{},
	fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			runProjectCmdCode(cmd, command, fileName)
		},
	}

	return cmd
}

// Destroy a Project
func destroyProjectCmd(commandName string, command map[string]interface{}, fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectnameFlag, err := cmd.Flags().GetString(projectNameFlagValue)
			shared.CheckForErrors(err)

			if projectnameFlag != "" && verbose {
				fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(projectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("---")
			}

			if projectnameFlag == "" {
				handleInputValues(command, true, nil)
			} else {
				projectName = projectnameFlag
			}

			//handleInputValues(command, true, nil)

			projectFound := false

			project := map[string]interface{}{}

			projectConfigurations := getProjectConfigurations()

			for pName, proj := range projectConfigurations {
				if pName == strings.ToLower(projectName) {
					projMap := proj.(map[string]interface{})
					for k, v := range projMap {
						project[k] = v
					}
					projectFound = true
				}
			}

			if !projectFound {
				fmt.Println("Project not found")
				return
			}

			arguments := command["arguments"].(map[string]interface{})

			logWrapper.Println("Called 'terraform.DestroyTerraform'")
			errTerrDestroy := terraform.DestroyTerraform(strings.ToLower(projectName), project,
				arguments, fileName, nil)
			shared.CheckForErrors(errTerrDestroy)
			logWrapper.Println("Completed 'terraform.DestroyTerraform'")
		},
	}

	return cmd
}
