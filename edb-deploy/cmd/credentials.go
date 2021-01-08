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
	"errors"
	"fmt"
	"io/ioutil"

	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

type credentials struct {
	YumUserName string
	YumPassword string
}

var creds = credentials{}

func createCredCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create-credentials",
		Short: "creating credentials for Deploy",
		Long:  "",
		RunE: func(cmd *cobra.Command, args []string) error {
			existingCreds := getCredentials()

			if existingCreds.YumUserName != "" && existingCreds.YumPassword != "" {
				fmt.Println("Credentials already exist, please run update-credentials command")
				return nil
			}

			if creds.YumUserName == "" {
				validate := func(input string) error {
					if len(input) == 0 {
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
					return err
				}

				creds.YumUserName = userName
			}

			if creds.YumPassword == "" {
				validate := func(input string) error {
					if len(input) == 0 {
						return errors.New("Passowrd cannot be empty")
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
					return err
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

	return cmd
}

func updateCredCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update-credentials",
		Short: "Update credentials for Deploy",
		Long:  "",
		RunE: func(cmd *cobra.Command, args []string) error {
			existingCreds := getCredentials()

			if existingCreds.YumUserName == "" && existingCreds.YumPassword == "" {
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
					userNameLabel = fmt.Sprintf("%s (%s)", userNameLabel, existingCreds.YumUserName)
				}

				prompt := promptui.Prompt{
					Label:    userNameLabel,
					Validate: validate,
				}

				userName, err := prompt.Run()
				if err != nil {
					return err
				}

				creds.YumUserName = userName
			}

			if creds.YumPassword == "" {
				validate := func(input string) error {
					if len(input) == 0 {
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
					return err
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

	return cmd
}

func deleteCredCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "delete-credentials",
		Short: "Delete credentials for Deploy",
		Long:  "",
		RunE: func(cmd *cobra.Command, args []string) error {
			existingCreds := getCredentials()
			if existingCreds.YumUserName == "" && existingCreds.YumPassword == "" {
				fmt.Println("No Credentials to delete")
				return nil
			}

			fileData := []byte("{}")
			ioutil.WriteFile(credFile, fileData, 0600)

			return nil
		},
	}

	return cmd
}

func init() {
	RootCmd.AddCommand(createCredCommand())
	RootCmd.AddCommand(updateCredCommand())
	RootCmd.AddCommand(deleteCredCommand())

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// versionCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// versionCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
