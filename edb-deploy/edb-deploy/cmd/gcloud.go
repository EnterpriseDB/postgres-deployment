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

// GCloud Cobra Commands
package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"
)

var gcloudCloudCmd = &cobra.Command{
	Use:   "gcloud",
	Short: "Gcloud specific commands",
	Long:  `Displays commands for gcloud`,
}

// GCloud Cobra Command Initialization
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

// GCloud Cobra Commands
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
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to detail")
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
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to delete")
		case "destroy":
			c := destroyProjectCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to destroy")
		case "deploy":
			c := deployProjectCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to deploy")
		case "run":
			c := runProjectCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to run")
		case "install":
			c := installCmd(a, bMap, fileName)
			gcloudCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to install")
		default:
			fmt.Println(d["name"].(string))
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	logWrapper.Println("Added GCloud Commands to Cobra")
	return command, nil
}
