package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
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

var projects = map[string]interface{}{}

func validate(argMap map[string]interface{}, defaultValue string) func(string) error {
	valid := func(input string) error {
		if argMap["type"] != nil && argMap["type"].(string) == "int" {
			inputFloat, err := strconv.ParseFloat(input, 64)
			if err != nil {
				return errors.New("Invalid number")
			}

			if argMap["validate"] != nil {
				validation := argMap["validate"].(map[string]interface{})
				if validation["minimum"] != nil {
					if inputFloat < validation["minimum"].(float64) {
						return errors.New("Must be greater than minumum")
					}
				}
				if validation["maximum"] != nil {
					if inputFloat > validation["maximum"].(float64) {
						return errors.New("Must be smaller than maximum")
					}
				}
			}

			return nil
		} else if argMap["type"] != nil && argMap["type"].(string) == "bool" {
			inputLower := strings.ToLower(input)
			if inputLower != "y" &&
				inputLower != "n" &&
				inputLower != "yes" &&
				inputLower != "no" &&
				inputLower != "false" &&
				inputLower != "true" &&
				inputLower != "t" &&
				inputLower != "f" {
				return errors.New(fmt.Sprintf("%s must be y or n", argMap["name"].(string)))
			}
		} else {
			if len(input) == 0 && defaultValue == "" {
				return errors.New(fmt.Sprintf("%s cannot be empty", argMap["name"].(string)))
			}
		}

		return nil
	}

	return valid
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

func getProjectNames() map[string]interface{} {
	projectNames := map[string]interface{}{}

	projectCredentials := getProjectCredentials()
	projectConfigurations := getProjectConfigurations()

	for pName, p := range projectCredentials {
		lowerPName := strings.ToLower(pName)
		if p != nil && len(p.(map[string]interface{})) != 0 {
			if projectNames[lowerPName] == nil {
				projectNames[lowerPName] = map[string]interface{}{
					"credentials":   true,
					"configuration": false,
				}
			} else {
				proj := projectNames[lowerPName].(map[string]interface{})
				proj["credentials"] = true
			}
		}
	}

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
		if isProjectAware {
			templates := &promptui.SelectTemplates{
				Label:    "{{ . }}",
				Selected: "Project Name: {{ . }}",
			}

			projectNamesMap := getProjectNames()
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
			validate := func(input string) error {
				if len(input) == 0 {
					return errors.New("Project Name cannot be empty")
				}
				return nil
			}

			prompt := promptui.Prompt{
				Label:    "Project Name",
				Validate: validate,
			}

			projectName, err = prompt.Run()

			if err != nil {
				return err
			}
		}
	}

	return nil
}

func handleInputValues(command map[string]interface{}, isProjectAware bool) error {
	var err error

	err = handleProjectNameInput(isProjectAware)
	if err != nil {
		return err
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
					defaultValue := ""
					newValue := ""
					flagDescription := argMap["flag_description"].(string)

					if argMap["default"] != nil {
						defaultValue = argMap["default"].(string)
						if argMap["encrypted"] != nil && argMap["encrypted"].(bool) {
							flagDescription = fmt.Sprintf("%s (******)", flagDescription)
						} else {
							flagDescription = fmt.Sprintf("%s (%s)", flagDescription, defaultValue)
						}
					}

					if argMap["options"] != nil && len(argMap["options"].([]interface{})) > 0 {
						templates := &promptui.SelectTemplates{
							Label:    "{{ . }}",
							Selected: fmt.Sprintf("%s: {{ . }}", flagDescription),
						}

						prompt := promptui.Select{
							Label:     flagDescription,
							Templates: templates,
							Items:     argMap["options"].([]interface{}),
						}

						_, newValue, err = prompt.Run()

						if err != nil {
							return err
						}
					} else {
						prompt := promptui.Prompt{
							Label:    flagDescription,
							Validate: validate(argMap, defaultValue),
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
						flowVariables[argMap["name"].(string)] = &defaultValue
					}

					if len(*flowVariables[argMap["name"].(string)]) == 0 {
						return fmt.Errorf("Yum Password cannot be empty")
					}
				}

				values[argMap["name"].(string)] = *flowVariables[argMap["name"].(string)]
			}
		}
	}

	return nil
}

func createFlags(cmd *cobra.Command, command map[string]interface{}) {
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

func createCredCommand(commandName string, command map[string]interface{}) *cobra.Command {
	instVaribles(command)

	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			err := handleInputValues(command, false)
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
	instVaribles(command)

	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			err := handleInputValues(command, false)
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

func getProjectCmd(commandName string, command map[string]interface{}) *cobra.Command {
	instVaribles(command)

	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			handleInputValues(command, true)

			projectFound := false

			project := map[string]interface{}{
				"credentials":   map[string]interface{}{},
				"configuration": map[string]interface{}{},
			}

			projectCredentials := getProjectCredentials()
			projectConfigurations := getProjectConfigurations()

			for pName, proj := range projectConfigurations {
				if pName == strings.ToLower(projectName) {
					project["configuration"] = proj
					projectFound = true
				}
			}

			for pName, proj := range projectCredentials {
				if pName == strings.ToLower(projectName) {
					project["credentials"] = proj
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

	var cmds map[string]interface{}

	_ = json.Unmarshal(commandConfiguration, &cmds)

	for a, b := range cmds {
		d := b.(map[string]interface{})

		switch d["name"].(string) {
		case "create-credential":
			c := createCredCommand(a, b.(map[string]interface{}))

			command.AddCommand(c)
		case "create-configuration":
			c := createConfCommand(a, b.(map[string]interface{}))

			command.AddCommand(c)
		case "get-project":
			c := getProjectCmd(a, b.(map[string]interface{}))

			command.AddCommand(c)
		case "get-project-names":
			c := getProjectNamesCmd(a, b.(map[string]interface{}))

			command.AddCommand(c)
		default:
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	return command, nil
}
