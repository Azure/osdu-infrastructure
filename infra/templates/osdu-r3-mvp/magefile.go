//+build mage

// osdu-infrastructure task runner.
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// A build step that runs all tests.
func All() {
	mg.Deps(CentralTests)
	mg.Deps(ServiceTests)
	mg.Deps(PartitionTests)
}

// Execute Unit Tests for OSDU MVP Central Resources.
func CentralUnitTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running unit tests...")
	return FindAndRunTests("central_resources/tests/unit")
}

// Execute Integration Tests for OSDU MVP Central Resources.
func CentralIntegrationTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running integration tests...")
	return FindAndRunTests("central_resources/tests/integration")
}

// Execute Tests for OSDU MVP Central Resources.
func CentralTests() {
	mg.Deps(CentralUnitTest)
	mg.Deps(CentralIntegrationTest)
}

// Execute Unit Tests for OSDU MVP Service Resources.
func ServiceUnitTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running unit tests...")
	return FindAndRunTests("service_resources/tests/unit")
}

// Execute Integration Tests for OSDU MVP Service Resources.
func ServiceIntegrationTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running integration tests...")
	return FindAndRunTests("service_resources/tests/integration")
}

// Execute Tests for OSDU MVP Service Resources.
func ServiceTests() {
	mg.Deps(ServiceUnitTest)
	mg.Deps(ServiceIntegrationTest)
}

// Execute Unit Tests for OSDU MVP Partition Resources.
func PartitionUnitTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running unit tests...")
	return FindAndRunTests("data_partition/tests/unit")
}

// Execute Integration Tests for OSDU MVP Partition Resources.
func PartitionIntegrationTest() error {
	mg.Deps(Check)
	fmt.Println("INFO: Running integration tests...")
	return FindAndRunTests("data_partition/tests/integration")
}

// Execute Tests for OSDU MVP Partition Resources.
func PartitionTests() {
	mg.Deps(PartitionUnitTest)
	mg.Deps(PartitionIntegrationTest)
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

// Remove temporary build and test files.
func Clean() error {
	fmt.Println("INFO: Cleaning...")
	return filepath.Walk("./infra/modules", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && info.Name() == "vendor" {
			return filepath.SkipDir
		}
		if info.IsDir() && info.Name() == ".terraform" {
			os.RemoveAll(path)
			fmt.Printf("Removed \"%v\"\n", path)
			return filepath.SkipDir
		}
		if info.IsDir() && info.Name() == "terraform.tfstate.d" {
			os.RemoveAll(path)
			fmt.Printf("Removed \"%v\"\n", path)
			return filepath.SkipDir
		}
		if !info.IsDir() && (info.Name() == "terraform.tfstate" ||
			info.Name() == "terraform.tfplan" ||
			info.Name() == "terraform.tfstate.backup") {
			os.Remove(path)
			fmt.Printf("Removed \"%v\"\n", path)
		}
		return nil
	})
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
