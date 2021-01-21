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

// Package cmd
// AWS Cobra Command Helper Functions
package cmd

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/spf13/cobra"
)

// Flag Value
const projectNameFlagValue = "project-name"

// Lists the Project Names
func awsGetProjectNames() map[string]interface{} {
	projectNames := map[string]interface{}{}

	projectConfigurations := getProjectConfigurations()

	for pName, p := range projectConfigurations {
		lowerPName := strings.ToLower(pName)

		if p != nil && len(p.(map[string]interface{})) != 0 {
			if projectNames[lowerPName] == nil {
				projectNames[lowerPName] = map[string]interface{}{
					"credentials":   false,
					"configuration": true,
				}
			} else {
				proj := projectNames[lowerPName].(map[string]interface{})
				proj["configuration"] = true
			}
		}
	}

	logWrapper.Println(projectNames)

	return projectNames
}

// Displays Details of a Project
func awsGetProjectCmd(commandName string,
	command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			awsProjectnameFlag, err := cmd.Flags().GetString(projectNameFlagValue)
			shared.CheckForErrors(err)

			if awsProjectnameFlag != "" && verbose {
				fmt.Println("--- Debugging:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(awsProjectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("---")
			}

			if awsProjectnameFlag == "" {
				handleInputValues(command, true, nil)
			} else {
				projectName = awsProjectnameFlag
			}

			projectFound := false

			project := map[string]interface{}{
				"configuration": map[string]interface{}{},
			}

			projectConfigurations := getProjectConfigurations()

			for pName, proj := range projectConfigurations {
				if pName == strings.ToLower(projectName) {
					project["configuration"] = proj
					projectFound = true
				}
			}

			if !projectFound {
				fmt.Println("Project not found")
				return
			}

			projectJSON, _ := json.MarshalIndent(project, "", "  ")
			fmt.Println(string(projectJSON))
			logWrapper.Println(string(projectJSON))
		},
	}

	// createFlags(cmd, command)

	return cmd
}

// Lists Available Projects
func awsListProjectNamesCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectNames := awsGetProjectNames()
			projectJSON, _ := json.MarshalIndent(projectNames, "", "  ")

			if len(string(projectJSON)) == 2 {
				fmt.Println("No Projects found")
				logWrapper.Debug("No Projects found")
			} else {
				fmt.Println(string(projectJSON))
				logWrapper.Println(string(projectJSON))
			}
		},
	}

	return cmd
}
