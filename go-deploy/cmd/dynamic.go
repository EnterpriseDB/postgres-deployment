package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"sort"
	"strconv"
	"strings"

	"postgres-deployment/go-deploy/terraform"

	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

var flowVariables = map[string]*string{}
var values = map[string]interface{}{}
var encryptedValues = map[string]string{}
var projectName = ""

var projects = map[string]interface{}{}

func validateNumber(argMap map[string]interface{}, value float64) error {
	if argMap["validate"] != nil {
		validation := argMap["validate"].(map[string]interface{})
		if validation["minimum"] != nil {
			if value < validation["minimum"].(float64) {
				return errors.New("Must be greater than minumum")
			}
		}
		if validation["maximum"] != nil {
			if value > validation["maximum"].(float64) {
				return errors.New("Must be smaller than maximum")
			}
		}
	}

	return nil
}

func validateBool(input string, inputName string) error {
	if input != "y" &&
		input != "n" &&
		input != "yes" &&
		input != "no" &&
		input != "false" &&
		input != "true" &&
		input != "t" &&
		input != "f" {
		return errors.New(fmt.Sprintf("%s must be y or n", inputName))
	}

	return nil
}

func validate(argMap map[string]interface{}, currentValue string) func(string) error {
	valid := func(input string) error {
		if argMap["type"] != nil && argMap["type"].(string) == "int" {
			if len(input) != 0 {
				inputFloat, err := strconv.ParseFloat(input, 64)
				if err != nil {
					return errors.New("Invalid number")
				}

				err = validateNumber(argMap, inputFloat)
				if err != nil {
					return err
				}
			} else if currentValue != "" {
				currentValueFloat, err := strconv.ParseFloat(currentValue, 64)
				if err != nil {
					return errors.New("Invalid number")
				}

				err = validateNumber(argMap, currentValueFloat)
				if err != nil {
					return err
				}
			} else {
				return errors.New("Invalid number")
			}

			return nil
		} else if argMap["type"] != nil && argMap["type"].(string) == "bool" {
			if len(input) != 0 {
				inputLower := strings.ToLower(input)
				err := validateBool(inputLower, argMap["name"].(string))
				if err != nil {
					return err
				}
			} else if currentValue != "" {
				err := validateBool(currentValue, argMap["name"].(string))
				if err != nil {
					return err
				}
			} else {
				return errors.New(fmt.Sprintf("%s must be y or n", argMap["name"].(string)))
			}
		} else {
			if len(input) == 0 && currentValue == "" {
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
		projectNamesMap := getProjectNames()

		if isProjectAware {
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

func createCredCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			err := handleInputValues(command, false, nil)
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
			err := handleInputValues(command, false, nil)
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

func updateCredCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projects := getProjectCredentials()
			err := handleInputValues(command, true, projects)
			if err != nil {
				return err
			}

			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(credFile, fileData, 0600)

			return nil
		},
	}

	createFlags(cmd, command)

	return cmd
}

func updateConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projects := getProjectConfigurations()
			err := handleInputValues(command, true, projects)
			if err != nil {
				return err
			}

			projects[strings.ToLower(projectName)] = values

			fileData, _ := json.MarshalIndent(projects, "", "  ")

			ioutil.WriteFile(confFile, fileData, 0600)

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
			err := handleInputValues(command, true, projects)
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
			err := handleInputValues(command, true, projects)
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

func getProjectCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			handleInputValues(command, true, nil)

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

func runProjectCmd(commandName string, command map[string]interface{}, variables map[string]interface{}, fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			handleInputValues(command, true, nil)

			projectFound := false

			project := map[string]interface{}{}

			projectCredentials := getProjectCredentials()
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

			for pName, proj := range projectCredentials {
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
				return
			}

			arguments := command["arguments"].(map[string]interface{})

			err := terraform.RunTerraform(strings.ToLower(projectName), project, arguments, variables, fileName, nil)
			if err != nil {
				fmt.Println(err)
			}
		},
	}

	return cmd
}

func destroyProjectCmd(commandName string, command map[string]interface{}, fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			handleInputValues(command, true, nil)

			projectFound := false

			project := map[string]interface{}{}

			projectCredentials := getProjectCredentials()
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

			for pName, proj := range projectCredentials {
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
				return
			}

			arguments := command["arguments"].(map[string]interface{})

			err := terraform.DestroyTerraform(strings.ToLower(projectName), project, arguments, fileName, nil)
			if err != nil {
				fmt.Println(err)
			}
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

	var configuration map[string]interface{}

	_ = json.Unmarshal(commandConfiguration, &configuration)

	cmds := configuration["commands"].(map[string]interface{})
	variables := configuration["variables"].(map[string]interface{})

	for a, b := range cmds {
		bMap := b.(map[string]interface{})
		d := bMap

		switch d["name"].(string) {
		case "create-credential":
			c := createCredCommand(a, bMap)

			command.AddCommand(c)
		case "create-configuration":
			c := createConfCommand(a, bMap)

			command.AddCommand(c)
		case "get-project":
			c := getProjectCmd(a, bMap)

			command.AddCommand(c)
		case "get-project-names":
			c := getProjectNamesCmd(a, bMap)

			command.AddCommand(c)
		case "update-credential":
			c := updateCredCommand(a, bMap)

			command.AddCommand(c)
		case "update-configuration":
			c := updateConfCommand(a, bMap)

			command.AddCommand(c)
		case "delete-credential":
			c := deleteCredCommand(a, bMap)

			command.AddCommand(c)
		case "delete-configuration":
			c := deleteConfCommand(a, bMap)

			command.AddCommand(c)
		case "run-project":
			c := runProjectCmd(a, bMap, variables, fileName)

			command.AddCommand(c)
		case "destroy-project":
			c := destroyProjectCmd(a, bMap, fileName)

			command.AddCommand(c)
		default:
			fmt.Println(d["name"].(string))
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	return command, nil
}
