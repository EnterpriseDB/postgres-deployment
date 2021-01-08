// Test the command line interface developed in Go for
package main

import (
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
)

var binaryName = "edb-deploy"
var binaryToExecute = "./" + binaryName
var cloudsToTest = []string{"aws", "azure", "gcloud"}
var rootCommandsToTest = []string{"create-credentials",
	"delete-credentials", "update-credentials", "version"}
var cloudCommandsToTest = []string{"configure", "delete", "deploy",
	"destroy", "get", "install", "list", "run"}

// Exit Status is result of the cancellation of UI Entries for a command
var expectedExitStatus1 = 1

// Exit Status for a failed Command that required an argument or flag
var expectedExitStatus2 = 2

// Verifies a File Exists
func fileExists(name string) bool {
	if _, err := os.Stat(name); err != nil {
		if os.IsNotExist(err) {
			return false
		}
	}
	return true
}

// Tests if the project binary can be created
func TestMain(m *testing.M) {
	cmd := exec.Command("go", "build")
	_, err := cmd.CombinedOutput()
	fmt.Println(cmd)
	if err != nil {
		fmt.Println("Error building a binary")
		fmt.Println(err)
		os.Exit(1)
	}

	os.Exit(m.Run())
}

// Tests the CLI Root Commands
func TestRootCloudCommands(t *testing.T) {
	for _, rootCommand := range rootCommandsToTest {
		cmd := exec.Command(binaryToExecute, rootCommand)
		_, err := cmd.CombinedOutput()
		fmt.Println(cmd)
		exitStatus := cmd.ProcessState.ExitCode()
		if err != nil {
			// Some of the commands expect UI entry
			// Failure is expected because no manual entries
			// nor parameters are provided
			if expectedExitStatus1 != exitStatus {
				fmt.Printf("Error with: '%v %v'", binaryToExecute, rootCommand)
				os.Exit(1)
			}
		}
	}
}

// Tests the CLI for each Cloud Command
func TestClouds(t *testing.T) {
	for _, cloud := range cloudsToTest {
		cmd := exec.Command(binaryToExecute, cloud)
		_, err := cmd.CombinedOutput()
		fmt.Println(cmd)
		if err != nil {
			fmt.Printf("Error with: '%v %v'", binaryToExecute, cloud)
			fmt.Println(err)
			os.Exit(1)
		}
	}
}

// Tests the Commands for each Cloud
func TestCloudCommands(t *testing.T) {
	for _, cloud := range cloudsToTest {
		for _, cloudCommand := range cloudCommandsToTest {
			cmd := exec.Command(binaryToExecute, cloud, cloudCommand)
			_, err := cmd.CombinedOutput()
			fmt.Println(cmd)
			exitStatus := cmd.ProcessState.ExitCode()
			if err != nil {
				// Some of the commands expect UI entry
				// Failure is expected because no manual entries
				// nor parameters are provided
				if expectedExitStatus1 != exitStatus &&
					// We did not provide a paramter such as project name
					// making it an expected failure
					expectedExitStatus2 != exitStatus {
					fmt.Printf("Error with: '%v %v %v' ", binaryToExecute, cloud, cloudCommand)
					fmt.Println("Error: ", err)
					os.Exit(1)
				}
			}
		}
	}
}

// Verifies existence of Project Binary
func TestInit(t *testing.T) {
	// Binary Exists
	binaryExists := fileExists(binaryName)
	if !fileExists(binaryName) {
		t.Errorf("Could not build binary")
	}

	assert.Equal(t, binaryExists, true, "Could not build binary")
}
