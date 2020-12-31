package cmd

import (
	"fmt"
	"strings"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/terraform"
	"github.com/spf13/cobra"
)

func deployProjectCmd(commandName string,
	command map[string]interface{},
	fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			// runProjectCmd
			// projectnameFlag := cmd.Flag("projectname")

			// if projectnameFlag.Value.String() != "" && verbose {
			// 	fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
			// 	fmt.Println("Flags")
			// 	fmt.Println("project-name")
			// 	fmt.Println(projectnameFlag)
			// 	fmt.Println("ProjectName")
			// 	fmt.Println(projectName)
			// 	fmt.Println("---")
			// }

			// if projectnameFlag.Value.String() == "" {
			// 	handleInputValues(command, true, nil)
			// } else {
			// 	projectName = projectnameFlag.Value.String()
			// }

			// projectFound := false

			// project := map[string]interface{}{}

			// projectConfigurations := getProjectConfigurations()

			// if verbose {
			// 	fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
			// 	fmt.Println("project")
			// 	fmt.Println(project)
			// 	fmt.Println("Project Configurations")
			// 	fmt.Println(projectConfigurations)
			// 	fmt.Println("ProjectName")
			// 	fmt.Println(projectName)
			// 	fmt.Println("---")
			// }

			// for pName, proj := range projectConfigurations {
			// 	if pName == strings.ToLower(projectName) {
			// 		projMap := proj.(map[string]interface{})
			// 		for k, v := range projMap {
			// 			project[k] = v
			// 		}
			// 		projectFound = true
			// 	}
			// }

			// if !projectFound {
			// 	fmt.Println("Project not found!")
			// 	return
			// }

			// arguments := command["arguments"].(map[string]interface{})

			// err := terraform.RunTerraform(strings.ToLower(projectName), project, arguments,
			// 	variables, fileName, nil)
			// if err != nil {
			// 	fmt.Println(err)
			// }

			// copyFiles(fileName)

			runProjectCmdCode(cmd, command, fileName)

			// installCmd
			// projectnameFlag = cmd.Flag("projectname")

			// if projectnameFlag.Value.String() != "" && verbose {
			// 	fmt.Println("--- Debugging:")
			// 	fmt.Println("Flags")
			// 	fmt.Println("project-name")
			// 	fmt.Println(projectnameFlag)
			// 	fmt.Println("ProjectName")
			// 	fmt.Println(projectName)
			// 	fmt.Println("---")
			// }

			// if projectnameFlag.Value.String() == "" {
			// 	handleInputValues(command, true, nil)
			// } else {
			// 	projectName = projectnameFlag.Value.String()
			// }

			// projectFound = false

			// project = map[string]interface{}{}

			// credentials := getCredentials()
			// projectConfigurations = getProjectConfigurations()

			// for pName, proj := range projectConfigurations {
			// 	if pName == strings.ToLower(projectName) {
			// 		projMap := proj.(map[string]interface{})
			// 		for k, v := range projMap {
			// 			project[k] = v
			// 		}
			// 		projectFound = true
			// 	}
			// }

			// if !projectFound {
			// 	fmt.Println("Project not found")
			// 	return
			// }

			// arguments = command["arguments"].(map[string]interface{})

			// if verbose {
			// 	fmt.Println("--- Debugging - ansible.go - installCmd :")
			// 	fmt.Println("ProjectName")
			// 	fmt.Println(projectName)
			// 	fmt.Println("arguments")
			// 	fmt.Println(arguments)
			// 	fmt.Println("variables")
			// 	fmt.Println(variables)
			// 	fmt.Println("fileName")
			// 	fmt.Println(fileName)
			// 	fmt.Println("---")
			// }

			// project["user_name"] = credentials.YumUserName
			// project["password"] = credentials.YumPassword

			// err = terraform.RunAnsible(strings.ToLower(projectName), project,
			// 	arguments, variables, fileName, nil)
			// if err != nil {
			// 	fmt.Println(err)
			// }

			installCmdCode(cmd, command, fileName)
		},
	}
	return cmd
}

func runProjectCmdCode(cmd *cobra.Command,
	command map[string]interface{},
	fileName string) {
	projectnameFlag := cmd.Flag("projectname")

	if projectnameFlag.Value.String() != "" && verbose {
		fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
		fmt.Println("Flags")
		fmt.Println("project-name")
		fmt.Println(projectnameFlag)
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("---")
	}

	if projectnameFlag.Value.String() == "" {
		handleInputValues(command, true, nil)
	} else {
		projectName = projectnameFlag.Value.String()
	}

	projectFound := false

	project := map[string]interface{}{}

	projectConfigurations := getProjectConfigurations()

	if verbose {
		fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
		fmt.Println("project")
		fmt.Println(project)
		fmt.Println("Project Configurations")
		fmt.Println(projectConfigurations)
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("---")
	}

	for pName, proj := range projectConfigurations {
		if pName == strings.ToLower(projectName) {
			projMap := proj.(map[string]interface{})
			for k, v := range projMap {
				project[k] = v
			}
			projectFound = true
		}
	}

	if !projectFound {
		fmt.Println("Project not found!")
		return
	}

	arguments := command["arguments"].(map[string]interface{})

	err := terraform.RunTerraform(strings.ToLower(projectName), project, arguments,
		variables, fileName, nil)
	if err != nil {
		fmt.Println(err)
	}

	copyFiles(fileName)
}

func installCmdCode(cmd *cobra.Command,
	command map[string]interface{},
	fileName string) {
	projectnameFlag := cmd.Flag("projectname")

	if projectnameFlag.Value.String() != "" && verbose {
		fmt.Println("--- Debugging:")
		fmt.Println("Flags")
		fmt.Println("project-name")
		fmt.Println(projectnameFlag)
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("---")
	}

	if projectnameFlag.Value.String() == "" {
		handleInputValues(command, true, nil)
	} else {
		projectName = projectnameFlag.Value.String()
	}

	projectFound := false

	project := map[string]interface{}{}

	credentials := getCredentials()
	projectConfigurations := getProjectConfigurations()

	for pName, proj := range projectConfigurations {
		if pName == strings.ToLower(projectName) {
			projMap := proj.(map[string]interface{})
			for k, v := range projMap {
				project[k] = v
			}
			projectFound = true
		}
	}

	if !projectFound {
		fmt.Println("Project not found")
		return
	}

	arguments := command["arguments"].(map[string]interface{})

	if verbose {
		fmt.Println("--- Debugging - ansible.go - installCmd :")
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("arguments")
		fmt.Println(arguments)
		fmt.Println("variables")
		fmt.Println(variables)
		fmt.Println("fileName")
		fmt.Println(fileName)
		fmt.Println("---")
	}

	project["user_name"] = credentials.YumUserName
	project["password"] = credentials.YumPassword

	err := terraform.RunAnsible(strings.ToLower(projectName), project,
		arguments, variables, fileName, nil)
	if err != nil {
		fmt.Println(err)
	}
}

func runProjectCmd(commandName string,
	command map[string]interface{},
	fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			// projectnameFlag := cmd.Flag("projectname")

			// if projectnameFlag.Value.String() != "" && verbose {
			// 	fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
			// 	fmt.Println("Flags")
			// 	fmt.Println("project-name")
			// 	fmt.Println(projectnameFlag)
			// 	fmt.Println("ProjectName")
			// 	fmt.Println(projectName)
			// 	fmt.Println("---")
			// }

			// if projectnameFlag.Value.String() == "" {
			// 	handleInputValues(command, true, nil)
			// } else {
			// 	projectName = projectnameFlag.Value.String()
			// }

			// projectFound := false

			// project := map[string]interface{}{}

			// projectConfigurations := getProjectConfigurations()

			// if verbose {
			// 	fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
			// 	fmt.Println("project")
			// 	fmt.Println(project)
			// 	fmt.Println("Project Configurations")
			// 	fmt.Println(projectConfigurations)
			// 	fmt.Println("ProjectName")
			// 	fmt.Println(projectName)
			// 	fmt.Println("---")
			// }

			// for pName, proj := range projectConfigurations {
			// 	if pName == strings.ToLower(projectName) {
			// 		projMap := proj.(map[string]interface{})
			// 		for k, v := range projMap {
			// 			project[k] = v
			// 		}
			// 		projectFound = true
			// 	}
			// }

			// if !projectFound {
			// 	fmt.Println("Project not found!")
			// 	return
			// }

			// arguments := command["arguments"].(map[string]interface{})

			// err := terraform.RunTerraform(strings.ToLower(projectName), project, arguments,
			// 	variables, fileName, nil)
			// if err != nil {
			// 	fmt.Println(err)
			// }

			// copyFiles(fileName)

			runProjectCmdCode(cmd, command, fileName)
		},
	}

	return cmd
}

func destroyProjectCmd(commandName string, command map[string]interface{}, fileName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectnameFlag := cmd.Flag("projectname")

			if projectnameFlag.Value.String() != "" && verbose {
				fmt.Println("--- Debugging - terraform.go - runProjectCmd:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(projectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("---")
			}

			if projectnameFlag.Value.String() == "" {
				handleInputValues(command, true, nil)
			} else {
				projectName = projectnameFlag.Value.String()
			}

			//handleInputValues(command, true, nil)

			projectFound := false

			project := map[string]interface{}{}

			projectConfigurations := getProjectConfigurations()

			for pName, proj := range projectConfigurations {
				if pName == strings.ToLower(projectName) {
					projMap := proj.(map[string]interface{})
					for k, v := range projMap {
						project[k] = v
					}
					projectFound = true
				}
			}

			if !projectFound {
				fmt.Println("Project not found")
				return
			}

			arguments := command["arguments"].(map[string]interface{})

			err := terraform.DestroyTerraform(strings.ToLower(projectName), project,
				arguments, fileName, nil)
			if err != nil {
				fmt.Println(err)
			}
		},
	}

	return cmd
}
