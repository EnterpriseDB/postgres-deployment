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

// Cobra Command Flag Helpers
package cmd

import (
	"github.com/spf13/cobra"
)

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
		cmd.PersistentFlags().StringVarP(&projectName, projectNameFlagValue,
			projectNameShort, "", "Name of the project")
	}
}
