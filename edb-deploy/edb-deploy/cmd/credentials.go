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

// Credentials Management
package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

type credentials struct {
	YumUserName string
	YumPassword string
}

var creds = credentials{}

// Cobra Command: Creates Credentials
func createCredCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create-credentials",
		Short: "creating credentials for Deploy",
		Long:  "",
		RunE: func(cmd *cobra.Command, args []string) error {
			existingCreds := getCredentials()

			if existingCreds.YumUserName != "" && existingCreds.YumPassword != "" {
				fmt.Println("Credentials already exist, please run update-credentials command")
				logWrapper.Println("Credentials already exist, please run update-credentials command")
				return nil
			}

			if creds.YumUserName == "" {
				validate := func(input string) error {
					if len(input) == 0 {
						logWrapper.Println("User Name cannot be empty")
						return errors.New("User Name cannot be empty")

					}
					return nil
				}

				prompt := promptui.Prompt{
					Label:    "Yum User Name",
					Validate: validate,
				}

				userName, err := prompt.Run()
				if err != nil {
					return shared.CheckForErrors(err)
				}

				creds.YumUserName = userName
			}

			if creds.YumPassword == "" {
				validate := func(input string) error {
					if len(input) == 0 {
						logWrapper.Println("Password cannot be empty")
						return errors.New("Password cannot be empty")
					}
					return nil
				}

				prompt := promptui.Prompt{
					Label:    "Yum password",
					Validate: validate,
					Mask:     '*',
				}

				password, err := prompt.Run()
				if err != nil {
					return shared.CheckForErrors(err)
				}

				creds.YumPassword = password
			}

			fileData, _ := json.MarshalIndent(creds, "", "  ")

			if verbose {
				fmt.Println("credFile")
				fmt.Println(credFile)
				fmt.Println("fileData")
				fmt.Println(fileData)
			}

			ioutil.WriteFile(credFile, fileData, 0600)

			return nil
		},
	}

	cmd.PersistentFlags().StringVarP(&creds.YumUserName, "yum-username", "u", "", "EDB Yum Username")
	cmd.PersistentFlags().StringVarP(&creds.YumPassword, "yum-password", "p", "", "EDB Yum Password")

	logWrapper.Println("Completed 'createCredCommand'")
	return cmd
}

// Cobra Command: Updates Credentials
func updateCredCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update-credentials",
		Short: "Update credentials for Deploy",
		Long:  "",
		RunE: func(cmd *cobra.Command, args []string) error {
			existingCreds := getCredentials()

			if existingCreds.YumUserName == "" &&
				existingCreds.YumPassword == "" {
				logWrapper.Println("Credentials do not exist, please run create-credentials command")
				fmt.Println("Credentials do not exist, please run create-credentials command")
				return nil
			}

			if creds.YumUserName == "" {
				validate := func(input string) error {
					if len(input) == 0 {
						return errors.New("User Name cannot be empty")
					}

					return nil
				}

				userNameLabel := "Yum User Name"

				if existingCreds.YumUserName != "" {
					userNameLabel = fmt.Sprintf("%s (%s)", userNameLabel,
						existingCreds.YumUserName)
				}

				prompt := promptui.Prompt{
					Label:    userNameLabel,
					Validate: validate,
				}

				userName, err := prompt.Run()
				if err != nil {
					return shared.CheckForErrors(err)
				}

				creds.YumUserName = userName
			}

			if creds.YumPassword == "" {
				validate := func(input string) error {
					if len(input) == 0 {
						logWrapper.Println("Password cannot be empty")
						return errors.New("Password cannot be empty")
					}
					return nil
				}

				passwordLabel := "Yum Password"

				if existingCreds.YumPassword != "" {
					passwordLabel = fmt.Sprintf("%s (*****)", passwordLabel)
				}

				prompt := promptui.Prompt{
					Label:    passwordLabel,
					Validate: validate,
					Mask:     '*',
				}

				password, err := prompt.Run()
				if err != nil {
					return shared.CheckForErrors(err)
				}

				creds.YumPassword = password
			}

			fileData, _ := json.MarshalIndent(creds, "", "  ")

			ioutil.WriteFile(credFile, fileData, 0600)

			return nil
		},
	}

	cmd.PersistentFlags().StringVarP(&creds.YumUserName, "yum-username", "u", "", "EDB Yum Username")
	cmd.PersistentFlags().StringVarP(&creds.YumPassword, "yum-password", "p", "", "EDB Yum Password")

	logWrapper.Println("Completed 'updateCredCommand'")
	return cmd
}

// Cobra Command: Delete Credentials
func deleteCredCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "delete-credentials",
		Short: "Delete credentials for Deploy",
		Long:  "",
		RunE: func(cmd *cobra.Command, args []string) error {
			existingCreds := getCredentials()
			if existingCreds.YumUserName == "" &&
				existingCreds.YumPassword == "" {
				logWrapper.Println("No Credentials to delete")
				fmt.Println("No Credentials to delete")
				return nil
			}

			fileData := []byte("{}")
			ioutil.WriteFile(credFile, fileData, 0600)

			fmt.Println("Deleted Credentials")
			logWrapper.Println("Completed 'deleteCredCommand'")

			return nil
		},
	}

	logWrapper.Println("Completed 'deleteCredCommand'")
	return cmd
}

// Adds Credential Cobra Commands
func init() {
	RootCmd.AddCommand(createCredCommand())
	RootCmd.AddCommand(updateCredCommand())
	RootCmd.AddCommand(deleteCredCommand())
	logWrapper.Println("Added Credential Cobra Commands")

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// versionCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// versionCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
