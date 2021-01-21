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

// UI Handlers
package cmd

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/manifoldco/promptui"
)

// Manages Project Name Entry
func handleProjectNameInput(isProjectAware bool) error {
	var err error
	if projectName == "" {
		projectNamesMap := awsGetProjectNames()

		if isProjectAware {
			if len(projectNamesMap) == 0 {
				return errors.New("No Projects Exist")
			}

			templates := &promptui.SelectTemplates{
				Label:    "{{ . }}",
				Selected: "Project Name: {{ . }}",
			}

			var projectNames []string

			for pName := range projectNamesMap {
				projectNames = append(projectNames, pName)
			}

			prompt := promptui.Select{
				Label:     "Project Name",
				Templates: templates,
				Items:     projectNames,
			}

			if _, projectName, err = prompt.Run(); err != nil {
				return shared.CheckForErrors(err)
			}
		} else {
			var projectNames []string

			for pName := range projectNamesMap {
				projectNames = append(projectNames, pName)
			}

			valid := func(input string) error {
				if len(input) == 0 {
					return errors.New("Project Name cannot be empty")
				}
				if projectNamesMap[input] != nil {
					return errors.New(fmt.Sprintf("Project '%s' already exists, please choose another Name or update existing project", input))
				}
				return nil
			}

			prompt := promptui.SelectWithAdd{
				Label:    "Project Name",
				Items:    projectNames,
				AddLabel: "New Project Name",
				Validate: valid,
			}

			_, projectName, err = prompt.Run()

			if err != nil {
				return err
			}
		}
	}

	logWrapper.Println("Completed 'handleProjectNameInput'")
	return nil
}

// Manages Value Entries
func handleInputValues(command map[string]interface{}, isProjectAware bool, projects map[string]interface{}) error {
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

	for element, value := range command {
		if element == "arguments" {
			valueMap := value.(map[string]interface{})

			keys := make([]int, 0)
			for keyString, _ := range valueMap {
				key, err := strconv.Atoi(keyString)
				if err != nil {
					return fmt.Errorf("Failed to build from meta-data")
				}
				keys = append(keys, key)
			}

			sort.Ints(keys)

			for _, k := range keys {
				keyString := strconv.Itoa(k)

				argMap := valueMap[keyString].(map[string]interface{})
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
		}
	}

	logWrapper.Println("Completed 'handleInputValues'")
	return nil
}
