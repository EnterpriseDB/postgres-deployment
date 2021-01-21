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
package cmd

import (
	"fmt"

	"github.com/EnterpriseDB/postgres-deployment/edb-deploy/shared"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

var instanceType = "c5.2xlarge"
var nameFilterKey = "name"
var locationFilterKey = "location"
var regionFilterKey = "region"

// var amiNameSearch = "CentOS Linux 7 x86_64 HVM EBS*"
var amiNameSearch = "CentOS 8*"

// var amiNameSearch = "RHEL-7.8-x86_64*"
// var amiNameSearch = "RHEL-8.2-x86_64*"
var awsRegion = "us-west-2"

func listInstanceTypeOfferings(session *session.Session, instanceType string,
	display bool, awsRegion string) bool {
	var instanceTypeOfferingFound bool = false

	svc := ec2.New(session, aws.NewConfig().WithRegion(awsRegion))
	if verbose {
		fmt.Println("Credentials:")
		fmt.Println(session.Config.Credentials.Get())
		fmt.Println("Session Region: ", *session.Config.Region)
		fmt.Println("Service Region: ", *svc.Config.Region)
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

	for _, instance := range result.InstanceTypeOfferings {
		if *instance.InstanceType == instanceType {
			if display {
				fmt.Println(*instance.InstanceType, " was found in: ", *instance.Location)
				logWrapper.Println(*instance.InstanceType, " was found in: ", *instance.Location)
			}
			instanceTypeOfferingFound = true
		}
	}

	return instanceTypeOfferingFound
}

func listInstanceAmiIDs(session *session.Session, display bool,
	awsRegion string) bool {
	var foundAmisInRegion bool = false

	svc := ec2.New(session, aws.NewConfig().WithRegion(awsRegion))
	if verbose {
		fmt.Println("Credentials:")
		fmt.Println(session.Config.Credentials.Get())
		fmt.Println("Session Region: ", *session.Config.Region)
		fmt.Println("Service Region: ", *svc.Config.Region)
	}

	filters := &ec2.DescribeImagesInput{
		Filters: []*ec2.Filter{
			{
				Name:   aws.String(nameFilterKey),
				Values: []*string{aws.String(amiNameSearch)},
			},
		},
	}

	result, err := svc.DescribeImages(filters)

	shared.CheckForErrors(err)

	for _, instance := range result.Images {
		if display {
			fmt.Println(*instance.Name)
			fmt.Println(*instance.ImageId)
		}
		foundAmisInRegion = true
	}

	logWrapper.Println("Were AMI's found in region: ", awsRegion, " ? ", foundAmisInRegion)
	return foundAmisInRegion
}
