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

// Converter Functions across Application
package cmd

// Converts Yes or No Values to Boolean
func convertBoolIn(input string) string {
	output := ""
	if input == "y" || input == "yes" || input == "true" || input == "t" {
		output = "true"
	} else if input == "n" || input == "no" || input == "false" || input == "f" {
		output = "false"
	}

	logWrapper.Println("Completed 'convertBoolIn'")
	return output
}

// Converts from Boolean to "y" or "n"
func convertBoolOut(input string) string {
	output := ""
	if input == "true" {
		output = "y"
	} else {
		output = "n"
	}

	logWrapper.Println("Completed 'convertBoolOut'")
	return output
}
