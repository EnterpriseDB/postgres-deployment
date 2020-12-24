package terraform

import (
	"os"
	"strconv"
)

var verbose bool = false

func getDebuggingStateFromOS() bool {
	var debuggingState bool

	// Retrieve from Environment variable debugging setting
	verboseValue, verbosePresent := os.LookupEnv("DEBUG")
	if verbosePresent {
		verbose, _ = strconv.ParseBool(verboseValue)
		debuggingState = true
	} else {
		debuggingState = false
	}

	return debuggingState
}
