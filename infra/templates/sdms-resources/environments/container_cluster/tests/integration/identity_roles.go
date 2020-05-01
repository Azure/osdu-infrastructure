package test

import (
	"fmt"
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
	"github.com/microsoft/cobalt/test-harness/terratest-extensions/modules/azure"
	"github.com/stretchr/testify/require"
)

// Verifies that the correct roles are assigned to the provisioned service principal
func verifyServicePrincipalRoleAssignments(t *testing.T, output infratests.TerraformOutput) {
	objectID := output["contributor_service_principal_object_id"].(string)
	actual := getActualRoleAssignmentsMap(t, output, objectID)
	expected := getSPExpectedRoleAssignmentsMap(output)

	for scope, role := range expected {
		require.Equal(t, actual[scope], role, fmt.Sprintf("Incorrect role has been assigned for resource %s", scope))
	}
}

// Verifies that the correct roles are assigned to app gateway's managed identity
func verifyAppGWMSIRoleAssignments(t *testing.T, output infratests.TerraformOutput) {
	objectID := output["app_gw_msi_object_id"].(string)
	actual := getActualRoleAssignmentsMap(t, output, objectID)
	expected := getAppGwMsiExpectedRoleAssignmentsMap(output)

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

// Constructs the expected service principal's role assignments based off the Terraform output
func getSPExpectedRoleAssignmentsMap(output infratests.TerraformOutput) map[string]string {
	expectedAssignments := map[string]string{}
	expectedAssignments[output["storage_account_id"].(string)] = "Contributor"
	expectedAssignments[output["container_registry_id"].(string)] = "AcrPull"
	expectedAssignments[output["storage_account_id"].(string)] = "Storage Blob Data Contributor"
	expectedAssignments[output["cosmos_id"].(string)] = "Contributor"

	return expectedAssignments
}

// Constructs the expected app gw identity role assignments based off the Terraform output
func getAppGwMsiExpectedRoleAssignmentsMap(output infratests.TerraformOutput) map[string]string {
	expectedAssignments := map[string]string{}
	expectedAssignments[output["app_gw_resource_id"].(string)] = "Contributor"
	expectedAssignments[output["resource_group_id"].(string)] = "Reader"

	return expectedAssignments
}
