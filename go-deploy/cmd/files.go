package cmd

import (
	"encoding/json"
	"io/ioutil"
	"log"
)

func getProjectCredentials() map[string]interface{} {
	content, err := ioutil.ReadFile(credFile)
	if err != nil {
		log.Fatal(err)
	}

	var credentials map[string]interface{}

	_ = json.Unmarshal(content, &credentials)

	return credentials
}

func getProjectConfigurations() map[string]interface{} {
	content, err := ioutil.ReadFile(confFile)
	if err != nil {
		log.Fatal(err)
	}

	var configurations map[string]interface{}

	_ = json.Unmarshal(content, &configurations)

	return configurations
}
