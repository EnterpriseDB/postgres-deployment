// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

// Cobra Command: Version
package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// Details about Cobra Command: Version
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number of EDB CLI",
	Long:  `This is current version of: edb-deploy`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("EDB v1.0")
	},
}

// Cobra Command: Version - Initialization
func init() {
	RootCmd.AddCommand(versionCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// versionCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// versionCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
