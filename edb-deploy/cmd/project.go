package cmd

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"github.com/spf13/cobra"
)

var projectPrefixName = "projects"

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
	fileCopy(pemInputConf, projectPath, pemOutputConf)

	iInputConf := fmt.Sprintf("%s/inventory.yml", tPath)
	iOutputConf := fmt.Sprintf("%s/inventory.yml", projectPath)
	fileCopy(iInputConf, projectPath, iOutputConf)

	oInputConf := fmt.Sprintf("%s/os.csv", tPath)
	oOutputConf := fmt.Sprintf("%s/os.csv", projectPath)
	fileCopy(oInputConf, projectPath, oOutputConf)

	aInputConf := fmt.Sprintf("%s/add_host.sh", tPath)
	aOutputConf := fmt.Sprintf("%s/add_host.sh", projectPath)
	fileCopy(aInputConf, projectPath, aOutputConf)

	return nil
}

func createConfCommand(commandName string, command map[string]interface{}, fileName string) *cobra.Command {
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
