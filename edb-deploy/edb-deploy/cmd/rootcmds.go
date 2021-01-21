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

// CobraRoot Commands
package cmd

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/spf13/cobra"
)

var variables = map[string]interface{}{}

// Cobra Command: Project Configuration
func createConfCommand(commandName string, command map[string]interface{}, fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			groups := command["configuration-groups"].(map[string]interface{})

			if err := handleGroups(variables["configurations"].(map[string]interface{}),
				groups, false, nil); err != nil {
				return shared.CheckForErrors(err)
			}

			projects := getProjectConfigurations()
			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(confFile, fileData, 0600)

			root, path := getProjectPath()

			if _, err := os.Stat(root); os.IsNotExist(err) {
				os.MkdirAll(root, os.ModePerm)
			}

			if _, err := os.Stat(path); os.IsNotExist(err) {
				os.MkdirAll(path, os.ModePerm)
			}

			//copyFiles(fileName)

			return nil
		},
	}

	createFlags2(cmd, variables["configurations"].(map[string]interface{}), true)
	logWrapper.Println("Project configuration was created successfully")
	return cmd
}

// Cobra Command: Update Configuration
func updateConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projects := getProjectConfigurations()
			groups := command["configuration-groups"].(map[string]interface{})

			if err := handleGroups(variables["configurations"].(map[string]interface{}),
				groups, true, projects); err != nil {
				return shared.CheckForErrors(err)
			}

			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(confFile, fileData, 0600)
			return nil
		},
	}

	createFlags2(cmd, variables["configurations"].(map[string]interface{}), true)
	logWrapper.Println("Project configuration was updated successfully")
	return cmd
}

// Cobra Command: Delete Configuration
func deleteConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
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
				if err := handleProjectNameInput(true); err != nil {
					return shared.CheckForErrors(err)
				}
			} else {
				projectName = projectnameFlag
			}

			projects := getProjectConfigurations()

			if projectnameFlag != "" && verbose {
				fmt.Println("--- Debugging:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(projectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("projects")
				fmt.Println(projects)
				fmt.Println("---")
			}

			if projects[strings.ToLower(projectName)] == nil {
				logWrapper.Println("Project not found")
				return fmt.Errorf("Project not found")
			}

			delete(projects, strings.ToLower(projectName))

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(confFile, fileData, 0600)
			fmt.Println("Project: ", projectnameFlag, " was deleted successfully")
			logWrapper.Println("Project: ", projectnameFlag, " was deleted successfully")
			return nil
		},
	}

	// createFlags(cmd, command)
	logWrapper.Println("Project configuration was deleted successfully")
	return cmd
}
