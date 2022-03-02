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
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
	"github.com/microsoft/cobalt/test-harness/terratest-extensions/modules/azure"
	"github.com/stretchr/testify/require"
)

// Verifies that the correct roles are assigned to the provisioned service principal
func verifyServicePrincipalRoleAssignments(t *testing.T, output infratests.TerraformOutput) {
	actual := getActualRoleAssignmentsMap(t, output)
	expected := getExpectedRoleAssignmentsMap(output)

	// Note: there may be other role assignments added outside of this template. A good
	// example of this is the role assignment that enables the services to create
	// signed URLs for data that exists in storage accounts not managed by this
	// template.
	for k, v := range expected {
		require.Equal(t, v, actual[k], "Expected role assignment is incorrect!")
	}
}

// Queries Azure for the role assignments of the provisioned SP and transforms them into
// a simple-to-consume map type. The returned map will have a key equal to a scope and
// a value equal to the role name
func getActualRoleAssignmentsMap(t *testing.T, output infratests.TerraformOutput) map[string]string {
	objectID := output["contributor_service_principal_id"].(string)
	assignments := azure.ListRoleAssignments(t, subscription, objectID)
	assignmentsMap := map[string]string{}

	for _, assignment := range *assignments {
		scope := assignment.Properties.Scope
		roleID := assignment.Properties.RoleDefinitionID
		roleName := azure.RoleName(t, subscription, *roleID)
		assignmentsMap[*scope] = roleName
	}

	return assignmentsMap
}

// Constructs the expected role assignments based off the Terraform output
func getExpectedRoleAssignmentsMap(output infratests.TerraformOutput) map[string]string {
	expectedAssignments := map[string]string{}
	expectedAssignments[output["service_plan_id"].(string)] = "Contributor"
	expectedAssignments[output["container_registry_id"].(string)] = "Contributor"
	expectedAssignments[output["storage_account_id"].(string)] = "Storage Blob Data Contributor"
	expectedAssignments[output["sb_namespace_id"].(string)] = "Azure Service Bus Data Sender"

	//read cosmosdb resource id from cosmosdb output
	properties := output["cosmosdb_properties"].(map[string]interface{})
	cosmosDBProperties := properties["cosmosdb"].(map[string]interface{})
	expectedAssignments[cosmosDBProperties["id"].(string)] = "Contributor"

	for _, appID := range output["app_service_ids"].([]interface{}) {
		expectedAssignments[appID.(string)] = "Contributor"
	}

	return expectedAssignments
}
