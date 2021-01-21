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

// Ansible Functions
package cmd

import (
	"fmt"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/terraform"
	"github.com/spf13/cobra"
)

// Configures a deployed project
func installCmd(commandName string,
	command map[string]interface{},
	fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectnameFlag, err := cmd.Flags().GetString(projectNameFlagValue)
			shared.CheckForErrors(err)

			if projectnameFlag != "" && verbose {
				fmt.Println("--- Debugging:")
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
				logWrapper.Println("Project not found")
				return
			}

			arguments := command["arguments"].(map[string]interface{})

			if verbose {
				fmt.Println("--- Debugging - ansible.go - installCmd :")
				fmt.Println("ProjectName")
				fmt.Println(projectName)
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

			logWrapper.Println(project["user_name"])
			logWrapper.Println(project["password"])

			errTerrAns := terraform.RunAnsible(strings.ToLower(projectName), project,
				arguments, variables, fileName, nil)

			shared.CheckForErrors(errTerrAns)
		},
	}

	return cmd
}
