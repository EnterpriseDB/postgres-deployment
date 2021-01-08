// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

package cmd

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

func validateManualBool(input string) error {
	if input != "y" &&
		input != "n" &&
		input != "yes" &&
		input != "no" &&
		input != "false" &&
		input != "true" &&
		input != "t" &&
		input != "f" {
		return errors.New(fmt.Sprintf("input must be y or n"))
	}

	return nil
}

func validateNumber(argMap map[string]interface{}, value float64) error {
	if argMap["validate"] != nil {
		validation := argMap["validate"].(map[string]interface{})
		if validation["minimum"] != nil {
			if value < validation["minimum"].(float64) {
				return errors.New("Must be greater than minumum")
			}
		}
		if validation["maximum"] != nil {
			if value > validation["maximum"].(float64) {
				return errors.New("Must be smaller than maximum")
			}
		}
	}

	return nil
}

func validateBool(input string, inputName string) error {
	if input != "y" &&
		input != "n" &&
		input != "yes" &&
		input != "no" &&
		input != "false" &&
		input != "true" &&
		input != "t" &&
		input != "f" {
		return errors.New(fmt.Sprintf("%s must be y or n", inputName))
	}

	return nil
}

func validate(argMap map[string]interface{}, currentValue string) func(string) error {
	valid := func(input string) error {
		if argMap["type"] != nil && argMap["type"].(string) == "int" {
			if len(input) != 0 {
				inputFloat, err := strconv.ParseFloat(input, 64)
				if err != nil {
					return errors.New("Invalid number")
				}

				err = validateNumber(argMap, inputFloat)
				if err != nil {
					return err
				}
			} else if currentValue != "" {
				currentValueFloat, err := strconv.ParseFloat(currentValue, 64)
				if err != nil {
					return errors.New("Invalid number")
				}

				err = validateNumber(argMap, currentValueFloat)
				if err != nil {
					return err
				}
			} else {
				return errors.New("Invalid number")
			}

			return nil
		} else if argMap["type"] != nil && argMap["type"].(string) == "bool" {
			if len(input) != 0 {
				inputLower := strings.ToLower(input)
				err := validateBool(inputLower, argMap["name"].(string))
				if err != nil {
					return err
				}
			} else if currentValue != "" {
				err := validateBool(currentValue, argMap["name"].(string))
				if err != nil {
					return err
				}
			} else {
				return errors.New(fmt.Sprintf("%s must be y or n", argMap["name"].(string)))
			}
		} else {
			if len(input) == 0 && currentValue == "" {
				return errors.New(fmt.Sprintf("%s cannot be empty", argMap["name"].(string)))
			}
		}

		return nil
	}

	return valid
}
