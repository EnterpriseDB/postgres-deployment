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

// Error Functions
package shared

import (
	"fmt"

	"github.com/goph/emperror"
)

var logWrapper = CustomLogWrapper()

// Checks and Logs Errors
func CheckForErrors(err error) error {
	if err != nil {
		fmt.Println(emperror.With(err, "key", "value"))
		fmt.Println("Error: " + err.Error())
		logWrapper.Println(err)
		logWrapper.Fatal(err)
		return emperror.With(err, "key", "value")
	}

	return nil
}
