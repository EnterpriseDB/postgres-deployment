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

// AWS Cobra Command Helper Functions
package terraform

import (
	"fmt"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

var nameFilterKey = "name"
var locationFilterKey = "location"
var regionFilterKey = "region"

const (
	awsCentos7ami = "CentOS Linux 7 x86_64 HVM EBS*"
	awsCentos8ami = "CentOS 8*"
	awsRhel7ami   = "RHEL-7.8-x86_64*"
	awsRhel8ami   = "RHEL-8.2-x86_64*"
)

func listAwsInstanceTypeOfferings(instanceType string,
	display bool, awsRegion string) bool {
	var instanceTypeOfferingFound bool = false

	session := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc := ec2.New(session, aws.NewConfig().WithRegion(awsRegion))

	if verbose {
		logWrapper.Debug("Credentials:")
		logWrapper.Debug(session.Config.Credentials.Get())
		logWrapper.Debug("Session Region: ", *session.Config.Region)
		logWrapper.Debug("Service Region: ", *svc.Config.Region)
	}

	filters := []*ec2.Filter{
		&ec2.Filter{
			Name:   aws.String(locationFilterKey),
			Values: []*string{aws.String(awsRegion)},
		},
	}

	instanceTypeOfferingsInput := ec2.DescribeInstanceTypeOfferingsInput{Filters: filters}
	result, err := svc.DescribeInstanceTypeOfferings(&instanceTypeOfferingsInput)

	shared.CheckForErrors(err)

	if display {
		for _, instance := range result.InstanceTypeOfferings {
			if *instance.InstanceType == instanceType {
				fmt.Println(*instance.InstanceType, " was found in: ", *instance.Location)
				logWrapper.Println(*instance.InstanceType, " was found in: ", *instance.Location)
				if verbose {
					logWrapper.Debug("Instance Location:", *instance.Location)
					logWrapper.Debug("Instance Type: ", *instance.InstanceType)
				}
				instanceTypeOfferingFound = true
			}
		}
	} else {
		if len(result.InstanceTypeOfferings) > 0 {
			instanceTypeOfferingFound = true
		}
		if verbose {
			logWrapper.Debug("Instance Type Offer Found: ", instanceTypeOfferingFound)
		}

	}

	return instanceTypeOfferingFound
}

func listAwsInstanceAmiIDs(display bool,
	awsRegion string, operatingSystem string) (bool, string) {
	var foundAmisInRegion bool = false

	session := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc := ec2.New(session, aws.NewConfig().WithRegion(awsRegion))

	if verbose {
		logWrapper.Debug("Credentials:")
		logWrapper.Debug(session.Config.Credentials.Get())
		logWrapper.Debug("Session Region: ", *session.Config.Region)
		logWrapper.Debug("Service Region: ", *svc.Config.Region)
	}

	awsAMIToSearchFor := ""

	switch operatingSystem {
	case "CentOS7":
		awsAMIToSearchFor = "CentOS Linux 7 x86_64 HVM EBS*"
	case "CentOS8":
		awsAMIToSearchFor = "CentOS 8*"
	case "RHEL7":
		awsAMIToSearchFor = "RHEL-7.8-x86_64*"
	case "RHEL8":
		awsAMIToSearchFor = "RHEL-8.2-x86_64*"

	}
	filters := &ec2.DescribeImagesInput{
		Filters: []*ec2.Filter{
			{
				Name:   aws.String(nameFilterKey),
				Values: []*string{aws.String(awsAMIToSearchFor)},
			},
		},
	}

	result, err := svc.DescribeImages(filters)
	shared.CheckForErrors(err)

	amiIDToReturn := ""

	for _, instance := range result.Images {
		if display {
			fmt.Println(*instance.Name)
			fmt.Println(*instance.ImageId)
		}
		if verbose {
			logWrapper.Debug("Instance Name: ", *instance.Name)
			logWrapper.Debug("Instance Image Id: ", *instance.ImageId)
		}
		amiIDToReturn = *instance.ImageId
		foundAmisInRegion = true
		break
	}

	if verbose {
		logWrapper.Debug("Were AMI's found in region: ", awsRegion, " ? ", foundAmisInRegion)
	}
	return foundAmisInRegion, amiIDToReturn
}
