package cmd

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"strings"

	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

func deleteProjectCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			err := handleProjectNameInput(true)
			if err != nil {
				return err
			}

			prompt := promptui.Prompt{
				Label:    "Are you sure you want to delete this projec? [y/n]",
				Validate: validateManualBool,
			}

			shouldDelete, err := prompt.Run()
			if err != nil {
				return err
			}

			if convertBoolIn(shouldDelete) == "true" {
				projects := getProjectCredentials()
				if err != nil {
					return err
				}

				if projects[strings.ToLower(projectName)] == nil {
					return fmt.Errorf("Project not found")
				}

				delete(projects, strings.ToLower(projectName))

				fileData, _ := json.MarshalIndent(projects, "", "  ")

				ioutil.WriteFile(credFile, fileData, 0600)

				projects = getProjectConfigurations()
				if err != nil {
					return err
				}

				if projects[strings.ToLower(projectName)] == nil {
					return fmt.Errorf("Project not found")
				}

				delete(projects, strings.ToLower(projectName))

				fileData, _ = json.MarshalIndent(projects, "", "  ")

				ioutil.WriteFile(confFile, fileData, 0600)
			}

			return nil
		},
	}

	createFlags(cmd, command)

	return cmd
}

func deleteCredCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projects := getProjectCredentials()
			err := handleInputValues2(variables["credentials"].(map[string]interface{}), true, projects)
			if err != nil {
				return err
			}

			if projects[strings.ToLower(projectName)] == nil {
				return fmt.Errorf("Project not found")
			}

			delete(projects, strings.ToLower(projectName))

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(credFile, fileData, 0600)

			return nil
		},
	}

	createFlags(cmd, command)

	return cmd
}

func deleteConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projects := getProjectConfigurations()
			err := handleInputValues2(variables["configurations"].(map[string]interface{}), true, projects)
			if err != nil {
				return err
			}

			if projects[strings.ToLower(projectName)] == nil {
				return fmt.Errorf("Project not found")
			}

			delete(projects, strings.ToLower(projectName))

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(confFile, fileData, 0600)

			return nil
		},
	}

	createFlags(cmd, command)

	return cmd
}
