//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

// Build a script to format and run tests of a Terraform module project
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// Default The default target when the command executes `mage` in Cloud Shell
var Default = RunAllTargets

func main() {
	Default()
}

// RunAllTargets A build step that runs Clean, Format, Unit and Integration in sequence
func RunAllTargets() {
	mg.Deps(CleanAll)
	mg.Deps(LintCheckGo)
	mg.Deps(LintCheckTerraform)
	mg.Deps(RunTestHarnessUnitTests)
	mg.Deps(RunUnitTests)
	mg.Deps(RunIntegrationTests)
}

// RunTestHarnessUnitTests run unit test for the test harness itself
func RunTestHarnessUnitTests() error {
	return sh.RunV("go", "test", "github.com/microsoft/cobalt/test-harness/infratests")
}

// RunUnitTests A build step that runs unit tests
func RunUnitTests() error {
	fmt.Println("INFO: Running unit tests...")
	return FindAndRunTests("unit")
}

// RunIntegrationTests A build step that runs integration tests
func RunIntegrationTests() error {
	fmt.Println("INFO: Running integration tests...")
	return FindAndRunTests("integration")
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

// LintCheckGo A build step that fails if go code is not formatted properly
func LintCheckGo() error {
	fmt.Println("INFO: Checking format for Go files...")
	return verifyRunsQuietly("Run `go fmt ./...` to fix", "go", "fmt", "./...")
}

// LintCheckTerraform a build step that fails if terraform files are not formatted properly
func LintCheckTerraform() error {
	fmt.Println("INFO: Checking format for Terraform files...")
	return verifyRunsQuietly("Run `terraform fmt` to fix the offending files", "terraform", "fmt")
}

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

// CleanAll A build step that removes temporary build and test files
func CleanAll() error {
	fmt.Println("INFO: Cleaning...")
	return filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
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
		if !info.IsDir() && (info.Name() == "terraform.tfstate" ||
			info.Name() == "terraform.tfplan" ||
			info.Name() == "terraform.tfstate.backup") {
			os.Remove(path)
			fmt.Printf("Removed \"%v\"\n", path)
		}
		return nil
	})
}
