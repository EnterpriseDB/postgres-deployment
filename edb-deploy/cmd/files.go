// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

package cmd

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
)

func getCredentials() credentials {
	content, err := ioutil.ReadFile(credFile)
	fmt.Println(credFile)
	if err != nil {
		fmt.Println("13")
		log.Fatal(err)
	}

	var creds = credentials{}

	_ = json.Unmarshal(content, &creds)

	return creds
}

func getProjectConfigurations() map[string]interface{} {
	content, err := ioutil.ReadFile(confFile)
	if err != nil {
		fmt.Println("27")
		log.Fatal(err)
	}

	var configurations map[string]interface{}

	_ = json.Unmarshal(content, &configurations)

	return configurations
}
