//+build mage

// osdu-infrastructure task runner.
package main

import (
	"fmt"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// A build step that runs all tests.
func All() {
	mg.Deps(TestCommonResources)
	mg.Deps(TestDataResources)
	mg.Deps(TestServiceResources)
}

// Execute Tests for R3 Common Resources.
func TestCommonResources() {
	mg.Deps(CommonUnitTest)
	mg.Deps(CommonIntegrationTest)
}

// Execute Unit Tests for OSDU R3 Common Resources.
func CommonUnitTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running unit tests...")
	return FindAndRunTests("common_resources/tests/unit")
}

// Execute Integration Tests for OSDU R3 Common Resources.
func CommonIntegrationTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running integration tests...")
	return FindAndRunTests("common_resources/tests/integration")
}

// Execute Tests for R3 Data Resources.
func TestDataResources() {
	mg.Deps(DataUnitTest)
	mg.Deps(DataIntegrationTest)
}

// Execute Unit Tests for OSDU R3 Data Resources.
func DataUnitTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running unit tests...")
	return FindAndRunTests("data_resources/tests/unit")
}

// Execute Integration Tests for OSDU R3 Data Resources.
func DataIntegrationTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running integration tests...")
	return FindAndRunTests("data_resources/tests/integration")
}

// Execute Tests for R3 Service Resources.
func TestServiceResources() {
	mg.Deps(ServiceUnitTest)
	mg.Deps(ServiceIntegrationTest)
}

// Execute Unit Tests for OSDU R3 Service Resources.
func ServiceUnitTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running unit tests...")
	return FindAndRunTests("service_resources/tests/unit")
}

// Execute Integration Tests for OSDU R3 Service Resources.
func ServiceIntegrationTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running integration tests...")
	return FindAndRunTests("service_resources/tests/integration")
}

// Validate both Terraform code and Go code.
func Check() {
	mg.Deps(LintTF)
	mg.Deps(LintGO)
}

// Lint check Go and fail if files are not not formatted properly.
func LintGO() error {
	fmt.Println("INFO: Checking format for Go files...")
	return verifyRunsQuietly("Run `go fmt ./...` to fix", "go", "fmt", "./...")
}

// Lint check Terraform and fail if files are not formatted properly.
func LintTF() error {
	fmt.Println("INFO: Checking format for Terraform files...")
	return verifyRunsQuietly("Run `terraform fmt --check --recursive` to fix the offending files", "terraform", "fmt")
}

//-------------------------------
// GO UTILITY FUNCTIONS
//-------------------------------

// runs a command and ensures that the exit code indicates success and that there is no output to stdout
func verifyRunsQuietly(instructionsToFix string, cmd string, args ...string) error {
	output, err := sh.Output(cmd, args...)

	if err != nil {
		return err
	}

	if len(output) == 0 {
		return nil
	}

	return fmt.Errorf("ERROR: command '%s' with arguments %s failed. Output was: '%s'. %s", cmd, args, output, instructionsToFix)
}

// FindAndRunTests finds all tests with a given path suffix and runs them using `go test`
func FindAndRunTests(pathSuffix string) error {
	goModules, err := sh.Output("go", "list", "./...")
	if err != nil {
		return err
	}

	testTargetModules := make([]string, 0)
	for _, module := range strings.Fields(goModules) {
		if strings.HasSuffix(module, pathSuffix) {
			testTargetModules = append(testTargetModules, module)
		}
	}

	if len(testTargetModules) == 0 {
		return fmt.Errorf("No modules found for testing prefix '%s'", pathSuffix)
	}

	cmdArgs := []string{"test"}
	cmdArgs = append(cmdArgs, testTargetModules...)
	cmdArgs = append(cmdArgs, "-v", "-timeout", "7200s")
	return sh.RunV("go", cmdArgs...)
}
