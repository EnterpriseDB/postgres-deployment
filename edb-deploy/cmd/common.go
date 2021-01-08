// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

// Common Functions across Application
package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

var projectPrefixName = "projects"
var flowVariables = map[string]*string{}
var values = map[string]interface{}{}
var cloudName = ""
var projectName = ""
var variables = map[string]interface{}{}
var encryptedValues = map[string]string{}

// Retrieves the value for Debugging from OS
func getDebuggingStateFromOS() bool {
	var debuggingState bool

	// Retrieve from Environment variable debugging setting
	verboseValue, verbosePresent := os.LookupEnv("DEBUG")
	if verbosePresent {
		verbose, _ = strconv.ParseBool(verboseValue)
		debuggingState = true
	} else {
		debuggingState = false
	}

	return debuggingState
}

// Gets Project Path
func getProjectPath() (string, string) {
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, projectPrefixName)
	splitPath = append(splitPath, cloudName)
	rootPath := strings.Join(splitPath, "/")
	splitPath = append(splitPath, projectName)
	projectPath := strings.Join(splitPath, "/")

	if verbose {
		fmt.Println("--- Debugging:")
		fmt.Println("cloudName")
		fmt.Println(cloudName)
		fmt.Println("projectPrefixName")
		fmt.Println(projectPrefixName)
		fmt.Println("projectPath")
		fmt.Println(projectPath)
		fmt.Println("---")
	}

	return rootPath, projectPath
}

// Gets Terraform Path
func getTerraformPath(cloudName string) string {
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, "terraform")
	splitPath = append(splitPath, cloudName)
	terraformPath := strings.Join(splitPath, "/")

	return terraformPath
}

// Gets Ansible Playbook Path
func getPlaybookPath() string {
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, "playbook")
	playbookPath := strings.Join(splitPath, "/")

	return playbookPath
}

// Copies a Files
func fileCopy(sourceFile string, destinationPath string, destinationFile string) {
	input, err := ioutil.ReadFile(sourceFile)
	if err != nil {
		fmt.Println(err)
		return
	}

	if _, err := os.Stat(destinationPath); os.IsNotExist(err) {
		os.MkdirAll(destinationPath, os.ModePerm)
	}

	err = ioutil.WriteFile(destinationFile, input, 0744)
	if err != nil {
		fmt.Println("Error creating", destinationFile)
		fmt.Println(err)
		return
	}
}

// Removes Empty Lines and Spaces from a File
func removeEmptyLinesAndSpaces(fileNameAndPath string) error {
	file, err := ioutil.ReadFile(fileNameAndPath)
	if err != nil {
		fmt.Println(err)
	}

	strFileContent := regexp.MustCompile(`[\t\r\n]+`).ReplaceAllString(strings.TrimSpace(string(file)), "\n")
	re := regexp.MustCompile("(?m)^\\s*$[\r\n]*")
	strFileContent = strings.Trim(re.ReplaceAllString(strFileContent, ""), "\r\n")
	err = ioutil.WriteFile(fileNameAndPath, []byte(strFileContent), 0644)

	if err != nil {
		fmt.Println(err)
	}

	return nil
}

// Checks for File Existence
func fileExists(fileNameAndPath string) bool {
	info, err := os.Stat(fileNameAndPath)

	if err != nil {
		fmt.Println(err)
	}

	if os.IsNotExist(err) {
		return false

	}
	return !info.IsDir()
}

// Changes Permissions for a File
func chmodFilePermissions(fileNameAndPath string) error {
	fileStats, err := os.Stat(fileNameAndPath)
	if verbose {
		fmt.Printf("File Permission before change: %s\n", fileStats.Mode())
	}
	// Set the File permissions to a more moderate setting
	err = os.Chmod(fileNameAndPath, 0600)
	if err != nil {
		return err
	}
	fileStats, err = os.Stat(fileNameAndPath)
	if verbose {
		fmt.Printf("File Permission after change: %s\n", fileStats.Mode())
	}

	return nil
}

// Copies Multiples Files
func copyFiles(fileName string) error {
	tPath := getTerraformPath(fileName)
	pPath := getPlaybookPath()
	_, projectPath := getProjectPath()

	ansInputConf := fmt.Sprintf("%s/ansible.cfg", pPath)
	ansOutputConf := fmt.Sprintf("%s/ansible.cfg", projectPath)
	fileCopy(ansInputConf, projectPath, ansOutputConf)

	psiInputConf := fmt.Sprintf("%s/playbook-single-instance.yml", pPath)
	psiOutputConf := fmt.Sprintf("%s/playbook-single-instance.yml", projectPath)
	fileCopy(psiInputConf, projectPath, psiOutputConf)

	pInputConf := fmt.Sprintf("%s/playbook.yml", pPath)
	pOutputConf := fmt.Sprintf("%s/playbook.yml", projectPath)
	fileCopy(pInputConf, projectPath, pOutputConf)

	rfrInputConf := fmt.Sprintf("%s/rhel_firewald_rule.yml", pPath)
	rfrOutputConf := fmt.Sprintf("%s/rhel_firewald_rule.yml", projectPath)
	fileCopy(rfrInputConf, projectPath, rfrOutputConf)

	hInputConf := fmt.Sprintf("%s/pem-inventory.yml", tPath)
	hOutputConf := fmt.Sprintf("%s/hosts.yml", projectPath)
	fileCopy(hInputConf, projectPath, hOutputConf)

	pemInputConf := fmt.Sprintf("%s/pem-inventory.yml", tPath)
	pemOutputConf := fmt.Sprintf("%s/pem-inventory.yml", projectPath)
	if verbose {
		fmt.Println("--- Debugging - project.go - copyFiles:")
		fmt.Println("projectPath")
		fmt.Println(projectPath)
		fmt.Println("pemOutputConf")
		fmt.Println(pemOutputConf)
	}
	fileCopy(pemInputConf, projectPath, pemOutputConf)
	removeEmptyLinesAndSpaces(pemOutputConf)

	iInputConf := fmt.Sprintf("%s/inventory.yml", tPath)
	iOutputConf := fmt.Sprintf("%s/inventory.yml", projectPath)
	if verbose {
		fmt.Println("--- Debugging - project.go - copyFiles:")
		fmt.Println("projectPath")
		fmt.Println(projectPath)
		fmt.Println("iOutputConf")
		fmt.Println(iOutputConf)
	}
	fileCopy(iInputConf, projectPath, iOutputConf)
	removeEmptyLinesAndSpaces(iOutputConf)

	oInputConf := fmt.Sprintf("%s/os.csv", tPath)
	oOutputConf := fmt.Sprintf("%s/os.csv", projectPath)
	fileCopy(oInputConf, projectPath, oOutputConf)

	aInputConf := fmt.Sprintf("%s/add_host.sh", tPath)
	aOutputConf := fmt.Sprintf("%s/add_host.sh", projectPath)
	fileCopy(aInputConf, projectPath, aOutputConf)

	return nil
}

// Converts Yes or No Values to Boolean
func convertBoolIn(input string) string {
	output := ""
	if input == "y" || input == "yes" || input == "true" || input == "t" {
		output = "true"
	} else if input == "n" || input == "no" || input == "false" || input == "f" {
		output = "false"
	}

	return output
}

// Converts from Boolean to "y" or "n"
func convertBoolOut(input string) string {
	output := ""
	if input == "true" {
		output = "y"
	} else {
		output = "n"
	}

	return output
}

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

	return nil
}

// Iterates JSON Metadata File for "arguments" element
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

// Iterates JSON Metadata File
func instVaribles2(vars map[string]interface{}) {
	for _, argValue := range vars {
		argMap := argValue.(map[string]interface{})
		var newArguement = ""
		flowVariables[argMap["name"].(string)] = &newArguement
	}
}

// Creates Flags for Cobra Commands
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

// Creates Flags for Cobra Commands
func createFlags2(cmd *cobra.Command, vars map[string]interface{}, shouldCreateProjectFlag bool) {
	instVaribles2(vars)

	for _, argValue := range vars {
		argMap := argValue.(map[string]interface{})

		if argMap["flag_name"] != nil {
			flagShort := ""
			if argMap["flag_short"] != nil {
				flagShort = argMap["flag_short"].(string)
			}

			cmd.PersistentFlags().StringVarP(flowVariables[argMap["name"].(string)],
				argMap["flag_name"].(string), flagShort, "",
				argMap["flag_description"].(string))
		}
	}

	if shouldCreateProjectFlag {
		cmd.PersistentFlags().StringVarP(&projectName, "project-name",
			"p", "", "Name of the project")
	}
}

// Cobra Command: Project Configuration
func createConfCommand(commandName string, command map[string]interface{}, fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			groups := command["configuration-groups"].(map[string]interface{})

			err := handleGroups(variables["configurations"].(map[string]interface{}),
				groups, false, nil)
			if err != nil {
				return err
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

// Cobra Command: Delete Configuration
func deleteConfCommand(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		RunE: func(cmd *cobra.Command, args []string) error {
			projectnameFlag := cmd.Flag("projectname")

			if projectnameFlag.Value.String() != "" && verbose {
				fmt.Println("--- Debugging:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(projectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("---")
			}

			if projectnameFlag.Value.String() == "" {
				err := handleProjectNameInput(true)
				if err != nil {
					return err
				}
			} else {
				projectName = projectnameFlag.Value.String()
			}

			projects := getProjectConfigurations()

			if projectnameFlag.Value.String() != "" && verbose {
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
