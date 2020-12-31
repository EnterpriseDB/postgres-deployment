package terraform

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"sort"
	"strings"

	"github.com/smallfish/simpleyaml"
)

var hardCodedPath = ""
var projectPrefixName = "projects"
var inventoryYamlFileName = "inventory.yml"
var clusterProjectDetailsFile = "projectdetails.txt"
var pgPasswordFileName = "postgres_pass"
var epasPasswordFileName = "enterprisedb_pass"
var pgTypeText = "pg_type"
var osText = "operating_system"
var osSlice = []string{"Centos7.7", "Centos8_1", "RHEL7.8", "RHEL8.2",
	"centos-7", "centos-8", "rhel-7", "rhel-8"}

func formatOS(os string) string {
	str := os
	stripped := strings.Replace(str, "_", ".", -1)
	stripped = strings.Replace(str, "-", "", -1)
	parts := strings.Split(stripped, ".")
	stripped = parts[0]
	stripped = strings.Replace(stripped, "os", "OS", -1)
	stripped = strings.Replace(stripped, "rhel", "RHEL", -1)
	stripped = strings.Replace(stripped, "cent", "Cent", -1)
	return string(stripped)
}

func findValueContainedInSlice(a []string, x string) (int, string) {
	for i, n := range a {
		if strings.Contains(n, x) {
			return i, n
		}
	}
	return len(a), ""
}

func readFileContent(fileNameAndPath string) string {
	fileContent, err := ioutil.ReadFile(fileNameAndPath)

	if err != nil {
		log.Println(err)
	}

	return string(fileContent)
}

func getProjectPath(projectName string, fileName string) string {
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, projectPrefixName)
	splitPath = append(splitPath, fileName)
	splitPath = append(splitPath, projectName)

	projectPath := strings.Join(splitPath, "/")

	return projectPath
}

func createClusterDetailsFile(projectName string,
	fileName string,
	ansibleUser string,
	pgType string) error {
	pgTypePassword := ""
	projectPath := getProjectPath(projectName, fileName)

	if pgType == "EPAS" {
		pgTypePassword = readFileContent(projectPath + "/.edbpass/" + epasPasswordFileName)
	} else {
		pgTypePassword = readFileContent(projectPath + "/.edbpass/" + pgPasswordFileName)
	}

	inventoryYamlFileName = projectPath + "/" + inventoryYamlFileName
	iYamlFile, err := ioutil.ReadFile(inventoryYamlFileName)
	if err != nil {
		panic(err)
	}

	iyaml, err := simpleyaml.NewYaml(iYamlFile)
	if err != nil {
		panic(err)
	}

	file, err := os.Create(projectPath + "/" + clusterProjectDetailsFile)

	if err != nil {
		panic(err)
	}

	pemServerPublicIP, err := iyaml.GetPath("all", "children", "pemserver", "hosts", "pemserver1", "ansible_host").String()

	if pemServerPublicIP != "" {
		fmt.Println("PEM SERVER:")
		file.WriteString("PEM SERVER:" + "\n")
		fmt.Println("-----------")
		file.WriteString("-----------" + "\n")
		fmt.Println("PEM URL: https://" + pemServerPublicIP + ":8443/pem")
		file.WriteString("PEM URL: https://" + pemServerPublicIP + ":8443/pem" + "\n")
	}

	if pgType == "EPAS" {
		fmt.Println("Username: enterprisedb")
		file.WriteString("Username: enterprisedb" + "\n")
		fmt.Println("Password: " + pgTypePassword)
		file.WriteString("Password: " + pgTypePassword + "\n")
	} else {
		fmt.Println("Username: postgres")
		file.WriteString("Username: postgres" + "\n")
		fmt.Println("Password: " + pgTypePassword)
		file.WriteString("Password: " + pgTypePassword + "\n")
	}

	primaryServers, err := iyaml.GetPath("all", "children", "primary", "hosts").GetMapKeys()

	if verbose {
		fmt.Println("--- Debugging - terraform - ansible.go - createClusterFileDetails :")
		fmt.Println("Primary Server: ", primaryServers)
		fmt.Println("Primary Server Value:", primaryServers[0])
		fmt.Println("---")
	}

	sort.Strings(primaryServers)

	fmt.Println(" ")
	file.WriteString("\n")

	if len(primaryServers) > 0 {
		fmt.Println("PRIMARY SERVERS:")
		file.WriteString("PRIMARY SERVERS:" + "\n")
		fmt.Println("---------------")
		file.WriteString("---------------" + "\n")
		fmt.Println("Username: ", ansibleUser)
		file.WriteString("Username: " + ansibleUser + "\n")
		for i := 0; i < len(primaryServers); i++ {
			primaryServersIP, err := iyaml.GetPath("all", "children", "primary", "hosts", primaryServers[i], "ansible_host").String()
			fmt.Println("SERVER: ", primaryServers[i])
			file.WriteString("SERVER: " + primaryServers[i] + "\n")
			fmt.Println("Public IP: ", primaryServersIP)
			file.WriteString("Public IP: " + primaryServersIP + "\n")
			if err != nil {
				panic(err)
			}
		}
	}

	fmt.Println(" ")
	file.WriteString("\n")

	standbyServers, err := iyaml.GetPath("all", "children", "standby", "hosts").GetMapKeys()
	if verbose {
		fmt.Println("--- Debugging - terraform - ansible.go - createClusterFileDetails :")
		fmt.Println("Standby Servers: ", standbyServers)
		fmt.Println("---")
	}
	sort.Strings(standbyServers)

	if len(standbyServers) > 0 {
		fmt.Println("STANDBY SERVERS:")
		file.WriteString("STANDBY SERVERS:" + "\n")
		fmt.Println("---------------")
		file.WriteString("---------------" + "\n")
		fmt.Println("Username: ", ansibleUser)
		file.WriteString("Username: " + ansibleUser + "\n")
		for i := 0; i < len(standbyServers); i++ {
			secondaryServersIP, err := iyaml.GetPath("all", "children", "standby", "hosts", standbyServers[i], "ansible_host").String()
			fmt.Println("STANDBY SERVER: ", standbyServers[i])
			file.WriteString("STANDBY SERVER: " + standbyServers[i] + "\n")
			fmt.Println("Public IP: ", secondaryServersIP)
			file.WriteString("Public IP: " + secondaryServersIP + "\n")
			if err != nil {
				panic(err)
			}
		}
	}

	fmt.Println(" ")
	err = file.Close()
	if err != nil {
		fmt.Println(err)
	}
	return nil
}

func RunAnsible(projectName string,
	project map[string]interface{},
	arguements map[string]interface{},
	variables map[string]interface{},
	fileName string,
	customTemplateLocation *string,
) error {
	projectPath := getProjectPath(projectName, fileName)

	// Retrieve from Environment variable debugging setting
	verbose = getDebuggingStateFromOS()

	setHardCodedVariables(project, variables)
	setMappedVariables(project, variables)

	passPath := fmt.Sprintf("%s/.edbpass", projectPath)

	project["pass_dir"] = passPath

	args := []string{"collection", "install", "edb_devops.edb_postgres", "--force"}

	comm := exec.Command("ansible-galaxy", args...)
	comm.Dir = projectPath

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)

	}

	fmt.Printf("%s\n", stdoutStderr)

	ansibleRun := arguements["ansible_run"].(map[string]interface{})
	extraVariableSlice := ansibleRun["extra_variables"].([]interface{})
	variableSlice := ansibleRun["variables"].([]interface{})

	ansibleExtraVars := ""

	for _, arg := range extraVariableSlice {
		argMap := arg.(map[string]interface{})
		value := ""

		if verbose {
			fmt.Println("--- Debugging - terraform - ansible.go - installCmd - extraVariables:")
			fmt.Println("extraVariableSlice")
			fmt.Println(extraVariableSlice)
			fmt.Println("variableSlice")
			fmt.Println(variableSlice)
			fmt.Println("variable")
			fmt.Println(project[argMap["variable"].(string)])
			fmt.Println("value")
			fmt.Println(project[argMap["variable"].(string)].(string))
		}

		value = project[argMap["variable"].(string)].(string)

		if verbose {
			fmt.Println("--- Debugging - terraform - ansible.go - installCmd - extraVariables:")
			fmt.Println("variable")
			fmt.Println(project[argMap["variable"].(string)])
			fmt.Println("value")
			fmt.Println(value)
		}

		if project[argMap["variable"].(string)] != nil {
			value = project[argMap["variable"].(string)].(string)
		} else if argMap["default"] != nil {
			value = argMap["default"].(string)
		}

		// position, retValue := findValueContainedInSlice(osSlice, value)
		// if position > -1 && retValue != "" {
		// 	if verbose {
		// 		fmt.Println("--- Debugging - terraform - ansible.go - installCmd - extraVariables - findValueContainedInSlice:")
		// 		fmt.Println("findValueContainedInSlice: true")
		// 		fmt.Println("osSlice")
		// 		fmt.Println(osSlice)
		// 	}
		// 	value = formatOS(retValue)
		// }

		if verbose {
			fmt.Println("--- Debugging - terraform - ansible.go - installCmd - extraVariables - findValueContainedInSlice:")
			fmt.Println("variable")
			fmt.Println(project[argMap["variable"].(string)])
			fmt.Println("Updated value")
			fmt.Println(value)
		}

		ansibleExtraVars = fmt.Sprintf("%s%s=%s ", ansibleExtraVars, argMap["prefix"], value)
	}

	project["extra_vars"] = ansibleExtraVars

	args = []string{"--ssh-common-args=-o StrictHostKeyChecking=no"}
	ansibleUser := ""
	pgType := ""

	for _, arg := range variableSlice {
		argMap := arg.(map[string]interface{})
		value := ""
		a := ""

		if project[argMap["variable"].(string)] != nil {
			value = project[argMap["variable"].(string)].(string)
			if verbose {
				fmt.Println("--- Debugging - terraform - ansible.go - installCmd :")
				fmt.Println("variable")
				fmt.Println(project[argMap["variable"].(string)])
				fmt.Println("value")
				fmt.Println(project[argMap["variable"].(string)].(string))
			}

			if strings.Contains(value, pgTypeText) {
				splitValue := strings.Split(value, " ")
				for i := 0; i < len(splitValue); i++ {
					if strings.Contains(splitValue[i], pgTypeText) {
						pgType = splitValue[i]
						pgType = strings.ReplaceAll(pgType, pgTypeText+"=", "")
					}
				}
			}
		} else if argMap["default"] != nil {
			value = argMap["default"].(string)
		}

		if argMap["prefix"] != nil {
			a = fmt.Sprintf("--%s=%s", argMap["prefix"], value)
			if argMap["prefix"] == "user" {
				ansibleUser = value
			}
		} else {
			a = value
		}

		args = append(args, a)
	}

	if verbose {
		fmt.Println("--- Debugging - terraform - ansible.go - installCmd :")
		fmt.Println("ProjectName")
		fmt.Println(projectName)
		fmt.Println("args")
		fmt.Println(args)
		fmt.Println("ansibleUser")
		fmt.Println(ansibleUser)
		fmt.Println("pgType")
		fmt.Println(pgType)
		fmt.Println("projectPath")
		fmt.Println(projectPath)
		fmt.Println("---")
	}

	comm = exec.Command("ansible-playbook", args...)
	comm.Dir = projectPath

	stdoutStderr, err = comm.CombinedOutput()
	if err != nil {
		fmt.Printf("%s\n", stdoutStderr)
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	createClusterDetailsFile(projectName, fileName,
		ansibleUser, pgType)

	return nil
}
