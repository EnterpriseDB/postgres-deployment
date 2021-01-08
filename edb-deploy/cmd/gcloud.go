// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

package cmd

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

func gcloudGetProjectNames() map[string]interface{} {
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

func gcloudGetProjectCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			gcloudProjectnameFlag := cmd.Flag("projectname")

			if gcloudProjectnameFlag.Value.String() != "" && verbose {
				fmt.Println("--- Debugging:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(gcloudProjectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("---")
			}

			if gcloudProjectnameFlag.Value.String() == "" {
				handleInputValues(command, true, nil)
			} else {
				projectName = gcloudProjectnameFlag.Value.String()
			}

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

func gcloudListProjectNamesCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectNames := gcloudGetProjectNames()

			projectJSON, _ := json.MarshalIndent(projectNames, "", "  ")
			//fmt.Println(string(projectJSON))

			if len(string(projectJSON)) == 2 {
				fmt.Println("No Projects found")
			} else {
				fmt.Println(string(projectJSON))
			}
		},
	}

	return cmd
}

var gcloudCloudCmd = &cobra.Command{
	Use:   "gcloud",
	Short: "Gcloud specific commands",
	Long:  `Displays commands for gcloud`,
}

func init() {
	RootCmd.AddCommand(gcloudCloudCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// versionCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// versionCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

func rootGcloudDynamicCommand(commandConfiguration []byte, fileName string) (*cobra.Command, error) {
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
		case "configure":
			c := createConfCommand(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
		case "get":
			c := gcloudGetProjectCmd(a, bMap)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP("projectname", "n", "", "The project name to detail")
		case "list":
			c := gcloudListProjectNamesCmd(a, bMap)
			gcloudCloudCmd.AddCommand(c)
		// Commented to prevent udpating the project details
		// case "update":
		// 	c := updateConfCommand(a, bMap)
		// 	gcloudCloudCmd.AddCommand(c)
		case "delete":
			c := deleteConfCommand(a, bMap)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP("projectname", "n", "", "The project name to delete")
		case "destroy":
			c := destroyProjectCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to destroy")
		case "deploy":
			c := deployProjectCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to deploy")
		case "run":
			c := runProjectCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to run")
		case "install":
			c := installCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to install")
		default:
			fmt.Println(d["name"].(string))
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	return command, nil
}
