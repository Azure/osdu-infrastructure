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

package test

import (
	"fmt"
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
	"github.com/microsoft/cobalt/test-harness/terratest-extensions/modules/azure"
	"github.com/stretchr/testify/require"
)

// Verifies that the correct roles are assigned to app gateway's managed identity
func verifyAGICRoleAssignments(t *testing.T, output infratests.TerraformOutput) {
	id := output["agic_identity_principal_id"].(string)
	actual := getActualRoleAssignmentsMap(t, output, id)
	expected := getAGICExpectedRoleAssignmentsMap(output)

	for scope, role := range expected {
		require.Equal(t, actual[scope], role, fmt.Sprintf("Incorrect role has been assigned for resource %s", scope))
	}
}

// Verifies that the correct roles are assigned to the cluster's kubelet managed identity
func verifyKubeletMSIRoleAssignments(t *testing.T, output infratests.TerraformOutput) {
	objectID := output["aks_kubelet_object_id"].(string)
	actual := getActualRoleAssignmentsMap(t, output, objectID)
	expected := getKubeletIdentityExpectedRoleAssignmentsMap(output)

	for scope, role := range expected {
		require.Equal(t, actual[scope], role, fmt.Sprintf("Incorrect role has been assigned for resource %s", scope))
	}
}

func verifyOSDUPodIdentityMSIRoleAssignments(t *testing.T, output infratests.TerraformOutput) {
	objectID := output["aad_osdu_identity_object_id"].(string)
	actual := getActualRoleAssignmentsMap(t, output, objectID)
	expected := getOSDUPodIdentityExpectedRoleAssignmentsMap(output)

	for scope, role := range expected {
		require.Equal(t, actual[scope], role, fmt.Sprintf("Incorrect role has been assigned for resource %s", scope))
	}
}

// Queries Azure for the role assignments of the provisioned SP and transforms them into
// a simple-to-consume map type. The returned map will have a key equal to a scope and
// a value equal to the role name
func getActualRoleAssignmentsMap(t *testing.T, output infratests.TerraformOutput, objectID string) map[string]string {
	assignments := azure.ListRoleAssignments(t, subscription, objectID)
	assignmentsMap := map[string]string{}

	for _, assignment := range *assignments {
		scope := assignment.Properties.Scope
		roleID := assignment.Properties.RoleDefinitionID
		roleName := azure.RoleName(t, subscription, *roleID)
		assignmentsMap[*scope] = roleName
	}

	fmt.Println("Actual map ", assignmentsMap)

	return assignmentsMap
}

// Constructs the expected app gw controller identity role assignments based off the Terraform output
func getAGICExpectedRoleAssignmentsMap(output infratests.TerraformOutput) map[string]string {
	expectedAssignments := map[string]string{}
	expectedAssignments[output["appgw_id"].(string)] = "Contributor"
	expectedAssignments[output["services_resource_group_id"].(string)] = "Reader"
	expectedAssignments[output["appgw_managed_identity_resource_id"].(string)] = "Managed Identity Operator"

	return expectedAssignments
}

// Constructs the expected kubelet managed identity role assignments based off the Terraform output
func getKubeletIdentityExpectedRoleAssignmentsMap(output infratests.TerraformOutput) map[string]string {
	expectedAssignments := map[string]string{}
	expectedAssignments[output["aks_node_resource_group_id"].(string)] = "Reader"
	expectedAssignments[output["aks_node_resource_group_id"].(string)] = "Virtual Machine Contributor"
	expectedAssignments[output["aks_node_resource_group_id"].(string)] = "Managed Identity Operator"
	expectedAssignments[output["akspod_identity_id"].(string)] = "Managed Identity Operator"
	expectedAssignments[output["agic_identity_id"].(string)] = "Managed Identity Operator"
	expectedAssignments[output["aad_osdu_identity_id"].(string)] = "Managed Identity Operator"
	expectedAssignments[output["container_registry_id"].(string)] = "AcrPull"

	return expectedAssignments
}

// Constructs the expected app gw controller identity role assignments based off the Terraform output
func getOSDUPodIdentityExpectedRoleAssignmentsMap(output infratests.TerraformOutput) map[string]string {
	expectedAssignments := map[string]string{}
	expectedAssignments[output["storage_account_id"].(string)] = "Storage Blob Data Contributor"
	expectedAssignments[output["keyvault_id"].(string)] = "Reader"
	expectedAssignments[output["cosmosdb_account_id"].(string)] = "Cosmos DB Account Reader Role"

	return expectedAssignments
}
