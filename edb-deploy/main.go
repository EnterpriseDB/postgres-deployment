// Purpose         : EDB CLI Go
// A command line interface developed in Go for
// deploying towards AWS, Azure, and Google Cloud
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

// A command line interface developed in Go for
// deploying towards AWS, Azure, and Google Cloud
package main

import "github.com/EnterpriseDB/postgres-deployment/edb-deploy/cmd"

// EDB CLI Go
func main() {
	cmd.Execute()
}
