package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

var flowVariables = map[string]*string{}
var values = map[string]interface{}{}
var encryptedValues = map[string]string{}
var projectName = ""
var variables = map[string]interface{}{}
var cloudName = ""

var projects = map[string]interface{}{}

func convertBoolIn(input string) string {
	output := ""
	if input == "y" || input == "yes" || input == "true" || input == "t" {
		output = "true"
	} else if input == "n" || input == "no" || input == "false" || input == "f" {
		output = "false"
	}

	return output
}

func convertBoolOut(input string) string {
	output := ""
	if input == "true" {
		output = "y"
	} else {
		output = "n"
	}

	return output
}

func instVaribles(command map[string]interface{}) {
	for element, value := range command {
		if element == "arguments" {
			for _, argValue := range value.(map[string]interface{}) {
				argMap := argValue.(map[string]interface{})
				var newArguement = ""
				flowVariables[argMap["name"].(string)] = &newArguement
			}
		}
	}
}

func instVaribles2(vars map[string]interface{}) {
	for _, argValue := range vars {
		argMap := argValue.(map[string]interface{})
		var newArguement = ""
		flowVariables[argMap["name"].(string)] = &newArguement
	}
}

func getProjectNames() map[string]interface{} {
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

	return projectNames
}

func handleProjectNameInput(isProjectAware bool) error {
	var err error
	if projectName == "" {
		projectNamesMap := getProjectNames()

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

			_, projectName, err = prompt.Run()

			if err != nil {
				return err
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

	return nil
}

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

	return nil
}

func createFlags(cmd *cobra.Command, command map[string]interface{}) {
	instVaribles(command)

	for element, value := range command {
		if element == "arguments" {
			for _, argValue := range value.(map[string]interface{}) {
				argMap := argValue.(map[string]interface{})
				flagShort := ""
				if argMap["flag_short"] != nil {
					flagShort = argMap["flag_short"].(string)
				}

				cmd.PersistentFlags().StringVarP(flowVariables[argMap["name"].(string)], argMap["flag_name"].(string), flagShort, "", argMap["flag_description"].(string))
			}
		}
	}

	cmd.PersistentFlags().StringVarP(&projectName, "project-name", "p", "", "Name of the project")
}

func createFlags2(cmd *cobra.Command, vars map[string]interface{}, shouldCreateProjectFlag bool) {
	instVaribles2(vars)

	for _, argValue := range vars {
		argMap := argValue.(map[string]interface{})

		if argMap["flag_name"] != nil {
			flagShort := ""
			if argMap["flag_short"] != nil {
				flagShort = argMap["flag_short"].(string)
			}

			cmd.PersistentFlags().StringVarP(flowVariables[argMap["name"].(string)], argMap["flag_name"].(string), flagShort, "", argMap["flag_description"].(string))
		}
	}

	if shouldCreateProjectFlag {
		cmd.PersistentFlags().StringVarP(&projectName, "project-name", "p", "", "Name of the project")
	}
}

func getProjectCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			handleInputValues(command, true, nil)

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
		},
	}

	createFlags(cmd, command)

	return cmd
}

func getProjectNamesCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectNames := getProjectNames()

			projectJSON, _ := json.MarshalIndent(projectNames, "", "  ")
			fmt.Println(string(projectJSON))
		},
	}

	return cmd
}

func rootDynamicCommand(commandConfiguration []byte, fileName string) (*cobra.Command, error) {
	command := &cobra.Command{
		Use:   fileName,
		Short: fmt.Sprintf("%s specific commands", fileName),
		Long:  ``,
	}

	cloudName = fileName

	var configuration map[string]interface{}

	_ = json.Unmarshal(commandConfiguration, &configuration)

	cmds := configuration["commands"].(map[string]interface{})
	variables = configuration["variables"].(map[string]interface{})

	for a, b := range cmds {
		bMap := b.(map[string]interface{})
		d := bMap

		switch d["name"].(string) {
		case "create-project":
			c := createConfCommand(a, bMap, fileName)

			command.AddCommand(c)
		case "get-project":
			c := getProjectCmd(a, bMap)

			command.AddCommand(c)
		case "get-project-names":
			c := getProjectNamesCmd(a, bMap)

			command.AddCommand(c)
		case "update-project":
			c := updateConfCommand(a, bMap)

			command.AddCommand(c)
		case "delete-project":
			c := deleteConfCommand(a, bMap)

			command.AddCommand(c)
		case "run-project":
			c := runProjectCmd(a, bMap, fileName)

			command.AddCommand(c)
		case "destroy-project":
			c := destroyProjectCmd(a, bMap, fileName)

			command.AddCommand(c)
		case "install-postgres":
			c := installCmd(a, bMap, fileName)

			command.AddCommand(c)
		default:
			fmt.Println(d["name"].(string))
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	return command, nil
}
