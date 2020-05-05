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
	"context"
	"fmt"
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/authorization/mgmt/2015-07-01/authorization"
)

type roleClients struct {
	DefinitionClient  authorization.RoleDefinitionsClient
	AssignmentsClient authorization.RoleAssignmentsClient
}

func getRoleClients(subscriptionID string) (*roleClients, error) {
	authorizer, err := DeploymentServicePrincipalAuthorizer()
	if err != nil {
		return nil, err
	}

	clients := roleClients{
		DefinitionClient:  authorization.NewRoleDefinitionsClient(subscriptionID),
		AssignmentsClient: authorization.NewRoleAssignmentsClient(subscriptionID),
	}

	clients.DefinitionClient.Authorizer = authorizer
	clients.AssignmentsClient.Authorizer = authorizer
	return &clients, nil
}

// ListRoleAssignmentsE - Return the role assignments for an object ID
func ListRoleAssignmentsE(subscriptionID, objectID string) (*[]authorization.RoleAssignment, error) {
	clients, err := getRoleClients(subscriptionID)
	if err != nil {
		return nil, err
	}

	paginatedResponse, err := clients.AssignmentsClient.List(context.Background(), fmt.Sprintf("principalId eq '%s'", objectID))
	results := []authorization.RoleAssignment{}
	if err != nil {
		return nil, err
	}

	for paginatedResponse.NotDone() {
		results = append(results, paginatedResponse.Values()...)
		err = paginatedResponse.Next()
		if err != nil {
			return nil, err
		}
	}

	return &results, nil
}

// ListRoleAssignments - Like ListRoleAssignmentsE but fails in the case an error is returned
func ListRoleAssignments(t *testing.T, subscriptionID, objectID string) *[]authorization.RoleAssignment {
	roleAssignments, err := ListRoleAssignmentsE(subscriptionID, objectID)
	if err != nil {
		t.Fatal(err)
	}
	return roleAssignments
}

// RoleNameE - Get the name of a role
func RoleNameE(subscriptionID, roleID string) (string, error) {
	clients, err := getRoleClients(subscriptionID)
	if err != nil {
		return "", err
	}

	role, err := clients.DefinitionClient.GetByID(context.Background(), roleID)
	if err != nil {
		return "", err
	}

	return *role.Properties.RoleName, nil
}

// RoleName - Like RoleNameE but fails in the case an error is returned
func RoleName(t *testing.T, subscriptionID, roleID string) string {
	name, err := RoleNameE(subscriptionID, roleID)
	if err != nil {
		t.Fatal(err)
	}
	return name
}
