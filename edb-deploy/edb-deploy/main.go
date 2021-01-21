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

// A command line interface developed in Go for
// deploying towards AWS, Azure, and Google Cloud
package main

import (
	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/cmd"
	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
)

var logWrapper = shared.CustomLogWrapper()

// EDB CLI Go
func main() {
	logWrapper.Println("Initializing EDB CLI Go...")
	cmd.Execute()
}
