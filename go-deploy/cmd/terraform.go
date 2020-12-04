package cmd

import (
	"fmt"
	"postgres-deployment/go-deploy/terraform"
	"strings"

	"github.com/spf13/cobra"
)

func runProjectCmd(commandName string, command map[string]interface{}, fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			handleInputValues(command, true, nil)

			projectFound := false

			project := map[string]interface{}{}

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

			if !projectFound {
				fmt.Println("Project not found")
				return
			}

			arguments := command["arguments"].(map[string]interface{})

			err := terraform.RunTerraform(strings.ToLower(projectName), project, arguments, variables, fileName, nil)
			if err != nil {
				fmt.Println(err)
			}

			copyFiles(fileName)
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
