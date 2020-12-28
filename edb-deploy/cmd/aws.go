package cmd

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

// var flowVariables = map[string]*string{}
// var values = map[string]interface{}{}
// var cloudName = ""
// var projectName = ""
// var variables = map[string]interface{}{}
// var encryptedValues = map[string]string{}

func awsGetProjectNames() map[string]interface{} {
	projectNames := map[string]interface{}{}

	projectConfigurations := getProjectConfigurations()

	for pName, p := range projectConfigurations {
		lowerPName := strings.ToLower(pName)

		if p != nil && len(p.(map[string]interface{})) != 0 {
			if projectNames[lowerPName] == nil {
				projectNames[lowerPName] = map[string]interface{}{
					"credentials":   false,
					"configuration": true,
				}
			} else {
				proj := projectNames[lowerPName].(map[string]interface{})
				proj["configuration"] = true
			}
		}
	}

	return projectNames
}

func awsGetProjectCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			awsProjectnameFlag := cmd.Flag("awsprojectname")

			if awsProjectnameFlag.Value.String() != "" && verbose {
				fmt.Println("--- Debugging:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(awsProjectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("---")
			}

			if awsProjectnameFlag.Value.String() == "" {
				handleInputValues(command, true, nil)
			} else {
				projectName = awsProjectnameFlag.Value.String()
			}

			projectFound := false

			project := map[string]interface{}{
				"configuration": map[string]interface{}{},
			}

			projectConfigurations := getProjectConfigurations()

			for pName, proj := range projectConfigurations {
				if pName == strings.ToLower(projectName) {
					project["configuration"] = proj
					projectFound = true
				}
			}

			if !projectFound {
				fmt.Println("Project not found")
				return
			}

			projectJSON, _ := json.MarshalIndent(project, "", "  ")
			fmt.Println(string(projectJSON))
		},
	}

	createFlags(cmd, command)

	return cmd
}

func awsListProjectNamesCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectNames := awsGetProjectNames()

			projectJSON, _ := json.MarshalIndent(projectNames, "", "  ")
			//fmt.Println(string(projectJSON))

			if len(string(projectJSON)) == 2 {
				fmt.Println("No Projects found")
			} else {
				fmt.Println(string(projectJSON))
			}
		},
	}

	return cmd
}

var awsCmd = &cobra.Command{
	Use:   "aws",
	Short: "Print the version number of EDB CLI",
	Long:  `This is current version of: edb-deploy`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("aws specific commands")
		if verbose {
			fmt.Println("--- Debugging - root.go - assignCloudDynamicRootCommand:")
			fmt.Println("Calling: assignCloudDynamicRootCommand")
			fmt.Println("./meta/aws.json")
			fmt.Println("---")
		}
		assignCloudDynamicRootCommand("./meta/aws.json")
	},
}

func init() {
	//RootCmd.AddCommand(awsCloudCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// versionCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// versionCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

func rootAWSDynamicCommand(commandConfiguration []byte, fileName string) (*cobra.Command, error) {
	command := &cobra.Command{
		Use:   fileName,
		Short: fmt.Sprintf("%s specific commands", fileName),
		Long:  ``,
	}

	cloudName = fileName

	var configuration map[string]interface{}

	_ = json.Unmarshal(commandConfiguration, &configuration)

	cmds := configuration["commands"].(map[string]interface{})
	variables = configuration["variables"].(map[string]interface{})

	for a, b := range cmds {
		bMap := b.(map[string]interface{})
		d := bMap

		switch d["name"].(string) {
		case "create":
			c := createConfCommand(a, bMap, fileName)
			command.AddCommand(c)
		case "get":
			c := awsGetProjectCmd(a, bMap)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "n", "", "The project name to use")
		case "list":
			c := awsListProjectNamesCmd(a, bMap)
			command.AddCommand(c)
		case "update":
			c := updateConfCommand(a, bMap)
			command.AddCommand(c)
		case "delete":
			c := deleteConfCommand(a, bMap)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "n", "", "The project name to use")
		case "run":
			c := awsRunProjectCmd(a, bMap, fileName)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to use")
		case "destroy":
			c := awsDestroyProjectCmd(a, bMap, fileName)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to use")
		case "install":
			c := awsInstallCmd(a, bMap, fileName)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to use")
		default:
			fmt.Println(d["name"].(string))
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	return command, nil
}
