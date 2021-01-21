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

// JSON Helper Functions
package cmd

// Iterates JSON Metadata File
func instVaribles2(vars map[string]interface{}) {
	for _, argValue := range vars {
		argMap := argValue.(map[string]interface{})
		var newArguement = ""
		flowVariables[argMap["name"].(string)] = &newArguement
	}
}
