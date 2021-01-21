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

// Common Terraform Functions
package terraform

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
)

const tagsInput string = "/tags.tf.template"
const tagsOutput string = "/tags.tf"

const variablesInput string = "/variables.tf.template"
const variablesOutput string = "/variables.tf"

// Replaces "PROJECT_NAME" with provided Project Name
// across terraform tag and variable files
func setVariableAndTagNames(projectName string) error {
	textToReplace := "PROJECT_NAME"

	if verbose {
		fmt.Println("--- Debugging - terraform -> run.go - setVariableAndTagNames:")
		fmt.Println("Starting...")
		fmt.Println("---")
	}

	tagTemplate, err := ioutil.ReadFile(fmt.Sprintf("%s%s", templateLocation, tagsInput))
	shared.CheckForErrors(err)

	tagsReplaced := bytes.ReplaceAll(tagTemplate, []byte(textToReplace), []byte(projectName))

	err = ioutil.WriteFile(fmt.Sprintf("%s%s", templateLocation, tagsOutput), tagsReplaced, 0644)
	shared.CheckForErrors(err)

	variableTemplate, err := ioutil.ReadFile(fmt.Sprintf("%s%s", templateLocation, variablesInput))
	shared.CheckForErrors(err)

	variablesReplaced := bytes.ReplaceAll(variableTemplate, []byte(textToReplace), []byte(projectName))

	err = ioutil.WriteFile(fmt.Sprintf("%s%s", templateLocation, variablesOutput), variablesReplaced, 0644)
	shared.CheckForErrors(err)

	if verbose {
		fmt.Println("--- Debugging - terraform -> run.go - setVariableAndTagNames:")
		fmt.Println("Leaving...")
		fmt.Println("---")
	}

	return nil
}

// Assigns Variables from json files as constants
func setHardCodedVariables(project map[string]interface{}, variables map[string]interface{}) error {
	if verbose {
		fmt.Println("--- Debugging - terraform -> run.go - setHardCodedVariables:")
		fmt.Println("Starting...")
		fmt.Println("---")
	}

	if variables != nil {
		hardCoded := variables["hard"].(map[string]interface{})

		for variable, value := range hardCoded {
			project[variable] = value
		}
	}

	if verbose {
		fmt.Println("--- Debugging - terraform -> run.go - setHardCodedVariables:")
		fmt.Println("Leaving...")
		fmt.Println("---")
	}

	return nil
}

// Maps variables in map section from json file
func setMappedVariables(project map[string]interface{}, variables map[string]interface{}) error {
	if verbose {
		fmt.Println("--- Debugging - terraform -> run.go - setMappedVariables:")
		fmt.Println("DEBUG")
		fmt.Println(verbose)
		fmt.Println("project")
		fmt.Println(project)
		fmt.Println("---")
	}

	if variables != nil {
		maps := variables["maps"].(map[string]interface{})

		if verbose {
			fmt.Println("--- Debugging:")
			fmt.Println("project")
			fmt.Println(project)
			fmt.Println("maps")
			fmt.Println(maps)
			fmt.Println("---")
		}

		for input, mapArray := range maps {
			mArr := mapArray.(map[string]interface{})
			for _, mMap := range mArr {
				m := mMap.(map[string]interface{})
				actualMap := m["map"].(map[string]interface{})
				out := ""

				if verbose {
					fmt.Println("--- Debugging:")
					fmt.Println("Interface for: m")
					fmt.Println(m)
					fmt.Println("project")
					fmt.Println(project)
					fmt.Println("input")
					fmt.Println(input)
				}

				if m["type"] == "starts-with" {
					for criteria, value := range actualMap {
						if strings.HasPrefix(project[input].(string), criteria) {
							out = value.(string)
						}
					}
				} else {
					val := project[input].(string)
					out = actualMap[val].(string)
				}

				project[m["output"].(string)] = out
				if verbose {
					fmt.Println("out")
					fmt.Println(out)
					fmt.Println("---")
				}
			}
		}
	}

	return nil
}
