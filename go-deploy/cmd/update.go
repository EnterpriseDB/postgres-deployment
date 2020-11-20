package cmd

import (
	"encoding/json"
	"io/ioutil"
	"strings"

	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

func updateProjectCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			handleProjectNameInput(true)

			prompt := promptui.Prompt{
				Label:    "Do you wish to update Credentials now? [y/n]",
				Validate: validateManualBool,
			}

			shouldUpdateCredentials, err := prompt.Run()
			if err != nil {
				return err
			}

			if convertBoolIn(shouldUpdateCredentials) == "true" {
				projects := getProjectCredentials()
				err := handleInputValues2(variables["credentials"].(map[string]interface{}), true, projects)
				if err != nil {
					return err
				}

				projects[strings.ToLower(projectName)] = values

				fileData, _ := json.MarshalIndent(projects, "", "  ")

				ioutil.WriteFile(credFile, fileData, 0600)
			}

			prompt = promptui.Prompt{
				Label:    "Do you wish to update Configuration now? [y/n]",
				Validate: validateManualBool,
			}

			shouldUpdateConfigure, err := prompt.Run()
			if err != nil {
				return err
			}

			if convertBoolIn(shouldUpdateConfigure) == "true" {
				projects := getProjectConfigurations()
				values = map[string]interface{}{}

				err = handleInputValues2(variables["configurations"].(map[string]interface{}), true, projects)
				if err != nil {
					return err
				}

				projects[strings.ToLower(projectName)] = values

				fileData, _ := json.MarshalIndent(projects, "", "  ")

				ioutil.WriteFile(confFile, fileData, 0600)
			}

			return nil
		},
	}

	createFlags2(cmd, variables["credentials"].(map[string]interface{}), true)
	createFlags2(cmd, variables["configurations"].(map[string]interface{}), false)

	return cmd
}

func updateCredCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projects := getProjectCredentials()
			groups := command["credential-groups"].(map[string]interface{})

			err := handleGroups(variables["credentials"].(map[string]interface{}), groups, true, projects)
			if err != nil {
				return err
			}

			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(credFile, fileData, 0600)

			return nil
		},
	}

	createFlags2(cmd, variables["credentials"].(map[string]interface{}), true)

	return cmd
}

func updateConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projects := getProjectConfigurations()
			groups := command["configuration-groups"].(map[string]interface{})

			err := handleGroups(variables["configurations"].(map[string]interface{}), groups, true, projects)
			if err != nil {
				return err
			}

			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(confFile, fileData, 0600)

			return nil
		},
	}

	createFlags2(cmd, variables["configurations"].(map[string]interface{}), true)

	return cmd
}
