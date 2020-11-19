package cmd

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"sort"
	"strconv"
	"strings"

	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

func handleInputValues2(vars map[string]interface{}, isProjectAware bool, projects map[string]interface{}) error {
	var err error

	err = handleProjectNameInput(isProjectAware)
	if err != nil {
		return err
	}

	existingValues := map[string]interface{}{}
	if projects != nil {
		projectInterface := projects[projectName]
		if projectInterface != nil {
			existingValues = projectInterface.(map[string]interface{})
		}
	}

	keys := make([]int, 0)
	for keyString, _ := range vars {
		key, err := strconv.Atoi(keyString)
		if err != nil {
			return fmt.Errorf("Failed to build from meta-data")
		}
		keys = append(keys, key)
	}

	sort.Ints(keys)

	for _, k := range keys {
		keyString := strconv.Itoa(k)

		argMap := vars[keyString].(map[string]interface{})
		if *flowVariables[argMap["name"].(string)] == "" {
			currentValue := ""
			newValue := ""
			flagDescription := argMap["flag_description"].(string)

			if argMap["default"] != nil {
				currentValue = argMap["default"].(string)
			}

			if existingValues != nil && existingValues[argMap["name"].(string)] != nil {
				currentValue = existingValues[argMap["name"].(string)].(string)
			}

			if currentValue != "" {
				if argMap["encrypted"] != nil && argMap["encrypted"].(bool) {
					flagDescription = fmt.Sprintf("%s (******)", flagDescription)
				} else if argMap["type"] != nil && argMap["type"].(string) == "bool" {
					displayBool := "n"
					if currentValue == "true" {
						displayBool = "y"
					}

					flagDescription = fmt.Sprintf("%s (%s)", flagDescription, displayBool)
				} else {
					flagDescription = fmt.Sprintf("%s (%s)", flagDescription, currentValue)
				}
			}

			if argMap["options"] != nil && len(argMap["options"].([]interface{})) > 0 {
				templates := &promptui.SelectTemplates{
					Label:    "{{ . }}",
					Selected: fmt.Sprintf("%s: {{ . }}", flagDescription),
				}

				currentValueIndex := 0
				for i, option := range argMap["options"].([]interface{}) {
					if option == currentValue {
						currentValueIndex = i
					}
				}

				prompt := promptui.Select{
					Label:     flagDescription,
					Templates: templates,
					Items:     argMap["options"].([]interface{}),
					CursorPos: currentValueIndex,
				}

				_, newValue, err = prompt.Run()

				if err != nil {
					return err
				}
			} else {
				prompt := promptui.Prompt{
					Label:    flagDescription,
					Validate: validate(argMap, currentValue),
				}

				if argMap["encrypted"] != nil && argMap["encrypted"].(bool) {
					prompt.Mask = '*'
				}

				newValue, err = prompt.Run()

				if argMap["type"] != nil && argMap["type"].(string) == "bool" {
					newValueLower := strings.ToLower(newValue)
					if newValueLower == "y" || newValueLower == "yes" || newValueLower == "true" || newValueLower == "t" {
						newValue = "true"
					} else if newValueLower == "n" || newValueLower == "no" || newValueLower == "false" || newValueLower == "f" {
						newValue = "false"
					}
				}

				if err != nil {
					return err
				}
			}

			if newValue != "" {
				flowVariables[argMap["name"].(string)] = &newValue
			} else {
				flowVariables[argMap["name"].(string)] = &currentValue
			}
		}

		values[argMap["name"].(string)] = *flowVariables[argMap["name"].(string)]
	}

	return nil
}

func createProjectCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			err := handleInputValues2(variables["credentials"].(map[string]interface{}), false, nil)
			if err != nil {
				return err
			}

			projects := getProjectCredentials()
			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(credFile, fileData, 0600)

			prompt := promptui.Prompt{
				Label:    "Do you wish to add configuration now? [y/n]",
				Validate: validateManualBool,
			}

			shouldConfigure, err := prompt.Run()
			if err != nil {
				return err
			}

			if convertBoolIn(shouldConfigure) == "true" {
				values = map[string]interface{}{}

				err = handleInputValues2(variables["configurations"].(map[string]interface{}), false, nil)
				if err != nil {
					return err
				}

				projects := getProjectConfigurations()
				projects[strings.ToLower(projectName)] = values

				fileData, _ := json.MarshalIndent(projects, "", "  ")

				ioutil.WriteFile(confFile, fileData, 0600)
			}

			return nil
		},
	}

	createFlags(cmd, command)

	return cmd
}

func createCredCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			err := handleInputValues2(variables["credentials"].(map[string]interface{}), false, nil)
			if err != nil {
				return err
			}

			projects := getProjectCredentials()
			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(credFile, fileData, 0600)

			return nil
		},
	}

	createFlags(cmd, command)

	return cmd
}

func createConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			err := handleInputValues2(variables["configurations"].(map[string]interface{}), false, nil)
			if err != nil {
				return err
			}

			projects := getProjectConfigurations()
			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(confFile, fileData, 0600)

			return nil
		},
	}

	createFlags(cmd, command)

	return cmd
}
