// Purpose         : EDB CLI Go
// Project         : postgres-deployment
// Author          : https://www.rocketinsights.com/
// Contributor     : Doug Ortiz
// Date            : January 07, 2021
// Version         : 1.0
// Copyright © 2020 EnterpriseDB

// Cobra Root
package cmd

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"

	homedir "github.com/mitchellh/go-homedir"
	"github.com/spf13/viper"
)

var (
	cfgFile     string
	DeployViper *viper.Viper
)

var jsonBase = []byte(`{}`)
var credFile = ""
var confFile = ""

var verbose bool = false
var metaPath = "./meta"
var metaFileExt = ".json"

// Cobra Root Command
var RootCmd = &cobra.Command{
	Use:   "edb-deploy",
	Short: "EDB edb-deploy Go CLI",
	Long:  `Copyright © 2020 EnterpriseDB`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		cmd.SilenceUsage = true
		return nil
	},
}

// Cobra Execute
func Execute() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

// Assigns JSON Metadata File based on Cloud Argument
func assignCloudDynamicRootCommand(file string) {
	content, err := ioutil.ReadFile(file)
	if err != nil {
		log.Fatal(err)
	}

	fileName := strings.Split(file, "/")[1]
	commandName := strings.Split(fileName, ".")[0]

	if verbose {
		fmt.Println("--- Debugging - root.go - assignCloudDynamicRootCommand:")
		fmt.Println("DEBUG")
		fmt.Println(verbose)
		fmt.Println("file")
		fmt.Println(file)
		fmt.Println("fileName")
		fmt.Println(fileName)
		fmt.Println("---")
	}

	command := &cobra.Command{
		Use:   "%s",
		Short: fmt.Sprintf("%s specific commands", fileName),
		Long:  ``,
	}

	switch {
	case strings.Contains(fileName, "aws"):
		command, err = rootAwsDynamicCommand(content, commandName)
	case strings.Contains(fileName, "azure"):
		command, err = rootAzureDynamicCommand(content, commandName)
	case strings.Contains(fileName, "gcloud"):
		command, err = rootGcloudDynamicCommand(content, commandName)
	default:
		fmt.Errorf("There was an error with the indicated cloud")
	}

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	RootCmd.AddCommand(command)
}

// Cobra Initialization
func init() {
	cobra.OnInitialize(initConfig)

	// Retrieve from Environment variable debugging setting
	verbose = getDebuggingStateFromOS()
	cloudName := ""

	// Command Line Argument
	cmdLineArgs := os.Args
	if os.Args != nil && len(os.Args) > 1 {
		cloudName = cmdLineArgs[1]
	}

	if verbose {
		fmt.Println("--- Debugging:")
		fmt.Println("DEBUG")
		fmt.Println(verbose)
		if cloudName != "" {
			fmt.Println("Cloud Command Line Argument")
			fmt.Println(cloudName)
		}
		fmt.Println("---")
	}

	var files []string

	root := metaPath
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		files = append(files, path)
		return nil
	})

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	for _, file := range files {
		if verbose {
			fmt.Println("--- Debugging:")
			fmt.Println("DEBUG")
			fmt.Println(verbose)
			if cloudName != "" {
				fmt.Println("Cloud Command Line Argument")
				fmt.Println(cloudName)
				fmt.Println("Matching Cloud Meta File")
				fmt.Println(cloudName + metaFileExt)
				fmt.Println("File Name in Meta Path")
				fmt.Println(file)
				fmt.Println("Cloud Meta File in Meta File Name and Extension?")
				fmt.Println(strings.Contains(file, cloudName+metaFileExt))
			}
			fmt.Println("---")
		}

		// Limits the Meta File to be processed to the matching Cloud
		if file != root && cloudName != "" &&
			strings.Contains(file, cloudName+metaFileExt) {
			assignCloudDynamicRootCommand(file)
		}
	}

	RootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// Config Initialization
func initConfig() {
	if cfgFile != "" {
		_, err := os.Stat(cfgFile)
		if os.IsNotExist(err) {
			os.Exit(1)
		}

		viper.SetConfigFile(cfgFile)
	} else {
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		credFile = fmt.Sprintf("%s/%s", home, ".edb/deploy-credentials.json")

		fmt.Println(credFile)
		_, err = os.Stat(credFile)

		if os.IsNotExist(err) {
			err = ioutil.WriteFile(credFile, jsonBase, 0600)
			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
		}

		confFile = fmt.Sprintf("%s/%s", home, ".edb/deploy-configurations.json")

		_, err = os.Stat(confFile)

		if os.IsNotExist(err) {
			err = ioutil.WriteFile(confFile, jsonBase, 0600)
			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
		}

		viper.SetConfigFile(confFile)
	}

	viper.AutomaticEnv()
}
