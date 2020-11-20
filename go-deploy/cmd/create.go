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

func handleGroups(vars map[string]interface{}, groups map[string]interface{}, isProjectAware bool, projects map[string]interface{}) error {
	err := handleProjectNameInput(isProjectAware)
	if err != nil {
		return err
	}

	keys := make([]int, 0)
	for keyString, _ := range groups {
		key, err := strconv.Atoi(keyString)
		if err != nil {
			return fmt.Errorf("Failed to build from meta-data")
		}
		keys = append(keys, key)
	}

	sort.Ints(keys)

	for _, k := range keys {
		keyString := strconv.Itoa(k)

		groupMap := groups[keyString].(map[string]interface{})
		handleVariables := false

		if groupMap["condition"] != nil {
			condition := groupMap["condition"].(map[string]interface{})
			conditionType := condition["type"].(string)

			if conditionType == "bool" {
				promptString := condition["prompt"].(string)
				prompt := promptui.Prompt{
					Label:    promptString,
					Validate: validateManualBool,
				}

				shouldHandleGroup, err := prompt.Run()
				if err != nil {
					return err
				}

				if convertBoolIn(shouldHandleGroup) == "true" {
					handleVariables = true
				}
			} else if conditionType == "variable" {
				equalsFunction := condition["equals"].(map[string]interface{})
				if equalsFunction["type"].(string) == "in" {
					options := equalsFunction["options"].([]interface{})

					for _, optionInterface := range options {
						option := optionInterface.(string)

						if values[equalsFunction["variable"].(string)] == option {
							handleVariables = true
						}
					}
				}
			}
		} else {
			handleVariables = true
		}

		if handleVariables {
			groupVars := map[string]interface{}{}
			variableNumbers := groupMap["variables"].([]interface{})

			for _, number := range variableNumbers {
				keyString := strconv.Itoa(int(number.(float64)))
				groupVars[keyString] = vars[keyString]

			}

			err := handleInputValues2(groupVars, isProjectAware, projects)
			if err != nil {
				return err
			}
		}
	}

	return nil
}

func handleInputValues2(vars map[string]interface{}, isProjectAware bool, projects map[string]interface{}) error {
	var err error

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
			groups := command["credential-groups"].(map[string]interface{})

			err := handleGroups(variables["credentials"].(map[string]interface{}), groups, false, nil)
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
				groups = command["configuration-groups"].(map[string]interface{})

				err = handleGroups(variables["configurations"].(map[string]interface{}), groups, false, nil)
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

	createFlags2(cmd, variables["credentials"].(map[string]interface{}), true)
	createFlags2(cmd, variables["configurations"].(map[string]interface{}), false)

	return cmd
}

func createCredCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			groups := command["credential-groups"].(map[string]interface{})

			err := handleGroups(variables["credentials"].(map[string]interface{}), groups, false, nil)
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

	createFlags2(cmd, variables["credentials"].(map[string]interface{}), true)

	return cmd
}

func createConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			groups := command["configuration-groups"].(map[string]interface{})

			err := handleGroups(variables["configurations"].(map[string]interface{}), groups, false, nil)
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

	createFlags2(cmd, variables["configurations"].(map[string]interface{}), true)

	return cmd
}
