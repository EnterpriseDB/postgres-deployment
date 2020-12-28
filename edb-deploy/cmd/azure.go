package cmd

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

// var azureFlowVariables = map[string]*string{}
// var azureValues = map[string]interface{}{}
// var azureEncryptedValues = map[string]string{}
// var azureProjectName = ""
// var azureVariables = map[string]interface{}{}
// var cloudName = ""
// var azureProjects = map[string]interface{}{}

func azureGetProjectNames() map[string]interface{} {
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

func azureGetProjectCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			azureProjectnameFlag := cmd.Flag("projectname")

			if azureProjectnameFlag.Value.String() != "" && verbose {
				fmt.Println("--- Debugging:")
				fmt.Println("Flags")
				fmt.Println("project-name")
				fmt.Println(azureProjectnameFlag)
				fmt.Println("ProjectName")
				fmt.Println(projectName)
				fmt.Println("---")
			}

			if azureProjectnameFlag.Value.String() == "" {
				handleInputValues(command, true, nil)
			} else {
				projectName = azureProjectnameFlag.Value.String()
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

func azureListProjectNamesCmd(commandName string, command map[string]interface{}) *cobra.Command {
	cmd := &cobra.Command{
		Use:   command["name"].(string),
		Short: command["short"].(string),
		Long:  command["long"].(string),
		Run: func(cmd *cobra.Command, args []string) {
			projectNames := azureGetProjectNames()

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

var azureCmd = &cobra.Command{
	Use:   "azure",
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

func rootAZUREDynamicCommand(commandConfiguration []byte, fileName string) (*cobra.Command, error) {
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
			c := azureGetProjectCmd(a, bMap)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "n", "", "The project name to use")
		case "list":
			c := azureListProjectNamesCmd(a, bMap)
			command.AddCommand(c)
		case "update":
			c := updateConfCommand(a, bMap)
			command.AddCommand(c)
		case "delete":
			c := deleteConfCommand(a, bMap)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "n", "", "The project name to use")
		case "run":
			c := azureRunProjectCmd(a, bMap, fileName)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to use")
		case "destroy":
			c := azureDestroyProjectCmd(a, bMap, fileName)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to use")
		case "install":
			c := azureInstallCmd(a, bMap, fileName)
			command.AddCommand(c)
			c.Flags().StringP("projectname", "p", "", "The project name to use")
		default:
			fmt.Println(d["name"].(string))
			return nil, fmt.Errorf("There was an error with the metadata")
		}
	}

	return command, nil
}
