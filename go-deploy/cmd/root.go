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

var RootCmd = &cobra.Command{
	Use:   "go-deploy",
	Short: "EDB postgres-deploy Go CLI",
	Long:  `Copyright © 2020 EnterpriseDB`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		cmd.SilenceUsage = true
		return nil
	},
}

func Execute() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)
	RootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	var files []string

	root := "./meta"
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		files = append(files, path)
		return nil
	})

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	for _, file := range files {
		if file != root {
			content, err := ioutil.ReadFile(file)
			if err != nil {
				log.Fatal(err)
			}

			fileName := strings.Split(file, "/")[1]
			commandName := strings.Split(fileName, ".")[0]

			command, err := rootDynamicCommand(content, commandName)

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
			RootCmd.AddCommand(command)
			RootCmd.AddCommand(createCredCommand())
			RootCmd.AddCommand(updateCredCommand())
			RootCmd.AddCommand(deleteCredCommand())
		}
	}
}

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
