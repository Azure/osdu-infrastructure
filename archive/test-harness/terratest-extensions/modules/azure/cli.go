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

package azure

import (
	"github.com/gruntwork-io/terratest/modules/shell"
	"os"
	"testing"
)

// CliServicePrincipalLoginE - Log into the local Azure CLI instance
func CliServicePrincipalLoginE(t *testing.T) error {
	return shell.RunCommandE(t, shell.Command{
		Command: "az",
		Args: []string{
			"login", "--service-principal",
			"-u", os.Getenv("ARM_CLIENT_ID"),
			"-p", os.Getenv("ARM_CLIENT_SECRET"),
			"--tenant", os.Getenv("ARM_TENANT_ID"),
		},
	})
}

// CliServicePrincipalLogin - Like CliServicePrincipalLoginE but fails in the case an error is returned
func CliServicePrincipalLogin(t *testing.T) {
	err := CliServicePrincipalLoginE(t)
	if err != nil {
		t.Fatal(err)
	}
}
