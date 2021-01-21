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

// Logging Functions
package shared

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/sirupsen/logrus"
)

var logPath = "logs/"
var logFileSuffix = "_log.txt"

// Logger Types
var (
	WarningLogger *log.Logger
	InfoLogger    *log.Logger
	ErrorLogger   *log.Logger
)

// Declare variables to store log messages as new Events
var (
	invalidArgMessage      = Event{1, "Invalid arg: %s"}
	invalidArgValueMessage = Event{2, "Invalid value for argument: %s: %v"}
	missingArgMessage      = Event{3, "Missing arg: %s"}
)

// Log Event
type Event struct {
	id      int
	message string
}

// StandardLogger
type StandardLogger struct {
	*logrus.Logger
}

// DebugLogger
type DebugLogger struct {
	*logrus.Logger
}

// Initializes Logging Settings
func CustomLogWrapper() *StandardLogger {
	currentDateAndTime := time.Now()
	// For Date and Time
	// logFilePrefix := fmt.Sprintf("%d-%02d-%02dT%02d:%02d:%02d",
	// 	currentDateAndTime.Year(), currentDateAndTime.Month(), currentDateAndTime.Day(),
	// 	currentDateAndTime.Hour(), currentDateAndTime.Minute(), currentDateAndTime.Second())
	// Only Date
	logFilePrefix := fmt.Sprintf("%d-%02d-%02d",
		currentDateAndTime.Year(), currentDateAndTime.Month(), currentDateAndTime.Day())
	logFilePathAndName := logPath + logFilePrefix + logFileSuffix
	logFile, err := os.OpenFile(logFilePathAndName,
		os.O_WRONLY|os.O_CREATE|os.O_CREATE|os.O_APPEND,
		0644)

	// formatter := new(log.TextFormatter)
	// log.SetFormatter(formatter)

	if err != nil {
		fmt.Println("Could not open log file: " + err.Error())
		// log.Fatal(err)
	}

	var baseLogger = logrus.New()
	var sLogger = &StandardLogger{baseLogger}
	sLogger.SetOutput(logFile)
	// sLogger.SetFormatter(&logrus.TextFormatter{})
	sLogger.SetFormatter(&logrus.JSONFormatter{})
	sLogger.SetLevel(logrus.DebugLevel)
	sLogger.SetReportCaller(true)

	// defer logFile.Close()
	return sLogger
}

// InvalidArg is a standard error message
func (l *StandardLogger) InvalidArg(argumentName string) {
	l.Errorf(invalidArgMessage.message, argumentName)
}

// InvalidArgValue is a standard error message
func (l *StandardLogger) InvalidArgValue(argumentName string, argumentValue string) {
	l.Errorf(invalidArgValueMessage.message, argumentName, argumentValue)
}

// MissingArg is a standard error message
func (l *StandardLogger) MissingArg(argumentName string) {
	l.Errorf(missingArgMessage.message, argumentName)
}
