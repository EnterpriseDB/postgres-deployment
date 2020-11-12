package terraform

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

func DestroyTerraform(project map[string]interface{}) error {
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	fmt.Println(project)

	splitPath := strings.Split(path, "/")

	if len(splitPath) > 0 {
		splitPath = splitPath[:len(splitPath)-1]
	}

	splitPath = append(splitPath, "terraform")
	splitPath = append(splitPath, "aws")

	projectName := "test1"
	joinedPath := strings.Join(splitPath, "/")
	region := "us-east-2"

	getTerraformWorkspace(projectName, joinedPath)
	terraformDestroy(region, joinedPath)
	deleteTerraformWorkspace(projectName, joinedPath)

	return nil
}

func getTerraformWorkspace(projectName string, joinedPath string) error {
	log.Printf("Checking Projects in terraform")

	comm := exec.Command("terraform", "workspace", "select", projectName)
	comm.Dir = joinedPath

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}

func terraformDestroy(region string, joinedPath string) error {
	log.Printf("Checking Projects in terraform")

	regionArguement := fmt.Sprintf(`-var=aws_region=%s`, region)

	comm := exec.Command("terraform", "destroy", "-auto-approve", regionArguement)
	comm.Dir = joinedPath

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}

func deleteTerraformWorkspace(projectName string, joinedPath string) error {
	log.Printf("Checking Projects in terraform")

	comm := exec.Command("terraform", "workspace", "select", "default")
	comm.Dir = joinedPath

	stdoutStderr, err := comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	comm = exec.Command("terraform", "workspace", "delete", projectName)
	comm.Dir = joinedPath

	stdoutStderr, err = comm.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", stdoutStderr)

	return nil
}
