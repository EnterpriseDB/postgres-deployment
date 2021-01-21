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

// Checks Helpers
package terraform

import (
	"os/exec"
	"strconv"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
)

var logWrapper = shared.CustomLogWrapper()

// Executes the pre-checks indicated in json file
func preCheck(check map[string]interface{},
	project map[string]interface{}) (string, error) {
	if check["log_text"] != nil {
		logWrapper.Printf(check["log_text"].(string))
	}

	output := ""

	if check["command"] != nil {
		command := check["command"].(string)
		if check["variables"] != nil {
			variables := check["variables"].(map[string]interface{})

			for i := 0; i < len(variables); i++ {
				iString := strconv.Itoa(i)
				variable := variables[iString].(string)

				if project[variable] != nil {
					value := strings.ReplaceAll(project[variable].(string), " ", "|||")
					command = strings.Replace(command, "%s", value, 1)
				}
			}
		}

		splitCommand := strings.Split(command, " ")

		for i, c := range splitCommand {
			splitCommand[i] = strings.ReplaceAll(c, "|||", " ")
		}

		comm := exec.Command(splitCommand[0], splitCommand[1:len(splitCommand)]...)

		stdoutStderr, err := comm.CombinedOutput()
		shared.CheckForErrors(err)
		if err != nil {
			logWrapper.Fatal(err)
		}

		output = strings.ReplaceAll(string(stdoutStderr), "\n", "")
	}

	logWrapper.Println("Completed 'preCheck'")
	return output, nil
}
