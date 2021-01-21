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

// AWS Cobra Commands
package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"
)

const projectNameShort = "p"

var awsCloudCmd = &cobra.Command{
	Use:   "aws",
	Short: "AWS specific commands",
	Long:  `Displays commands for AWS`,
}

// AWS Cobra Command Initialization
func init() {
	RootCmd.AddCommand(awsCloudCmd)
	logWrapper.Println("Added AWS Root Cobra Command")

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// versionCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// versionCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// AWS Cobra Commands
func rootAwsDynamicCommand(commandConfiguration []byte, fileName string) (*cobra.Command, error) {
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
			awsCloudCmd.AddCommand(c)
		case "get":
			c := awsGetProjectCmd(a, bMap)
			awsCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to use")
		case "list":
			c := awsListProjectNamesCmd(a, bMap)
			awsCloudCmd.AddCommand(c)
		// Commented to prevent udpating the project details
		// case "update":
		// 	c := updateConfCommand(a, bMap)
		// 	awsCloudCmd.AddCommand(c)
		case "delete":
			c := deleteConfCommand(a, bMap)
			awsCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to use")
		case "deploy":
			c := deployProjectCmd(a, bMap, fileName)
			awsCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to deploy")
		case "run":
			c := runProjectCmd(a, bMap, fileName)
			awsCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to use")
		case "install":
			c := installCmd(a, bMap, fileName)
			awsCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to use")
		case "destroy":
			c := destroyProjectCmd(a, bMap, fileName)
			awsCloudCmd.AddCommand(c)
			c.Flags().StringP(projectNameFlagValue, projectNameShort, "", "The project name to use")
		default:
			fmt.Println(d["name"].(string))
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	logWrapper.Println("Added AWS Commands to Cobra")
	return command, nil
}
