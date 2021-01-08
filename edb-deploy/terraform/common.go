// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

// Common Terraform Functions
package terraform

import (
	"os"
	"strconv"
)

var verbose bool = false

// Gets the Debug Value from OS
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
