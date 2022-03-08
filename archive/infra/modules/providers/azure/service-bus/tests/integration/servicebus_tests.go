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

package integraton

import (
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
	"github.com/microsoft/cobalt/test-harness/terratest-extensions/modules/azure"
	"github.com/stretchr/testify/require"
)

// healthCheck - Asserts that the deployment was successful.
func healthCheck(t *testing.T, provisionState *string) {
	require.Equal(t, "Succeeded", *provisionState, "The deployment hasn't succeeded.")
}

// VerifySubscriptionsList - validate list of subscriptions names for created topics
func VerifySubscriptionsList(subscriptionID, resourceGroupOutputName, namespaceOutputName, topicSubscriptionsOutputname string) func(goTest *testing.T, output infratests.TerraformOutput) {
	return func(goTest *testing.T, output infratests.TerraformOutput) {
		topicSubscriptionsMap := output[topicSubscriptionsOutputname].(map[string]interface{})

		namespaceName := output[namespaceOutputName].(string)
		resourceGroup := output[resourceGroupOutputName].(string)

		for topicName, topicsMap := range topicSubscriptionsMap {
			subscriptionNamesFromAzure := azure.ListTopicSubscriptionsName(
				goTest,
				subscriptionID,
				namespaceName,
				resourceGroup,
				topicName)

			subscriptionsMap := topicsMap.(map[string]interface{})["subscriptions"].(map[string]interface{})
			subscriptionNamesFromOutput := getMapKeylist(subscriptionsMap)

			// each subscription from the output should also exist in Azure
			require.Equal(goTest, len(*subscriptionNamesFromOutput), len(*subscriptionNamesFromAzure))
			for _, subscrptionName := range *subscriptionNamesFromOutput {
				require.Contains(goTest, *subscriptionNamesFromAzure, subscrptionName)
			}
		}
	}
}

// validate list of authentication rules  for the created topic
func verifyTopicAuthenticationRuleList(subscriptionID, resourceGroupOutputName, namespaceOutputName, topicSubscriptionsOutputname string) func(goTest *testing.T, output infratests.TerraformOutput) {
	return func(goTest *testing.T, output infratests.TerraformOutput) {
		topicAuthsMap := output[topicSubscriptionsOutputname].(map[string]interface{})

		namespaceName := output[namespaceOutputName].(string)
		resourceGroupName := output[resourceGroupOutputName].(string)

		for topicName, topicsMap := range topicAuthsMap {
			AuthRulesFromAzure := azure.ListTopicAuthRules(
				goTest,
				subscriptionID,
				namespaceName,
				resourceGroupName,
				topicName)

			authorizationMap := topicsMap.(map[string]interface{})["authorization_rules"].(map[string]interface{})
			authNamesFromOutput := getMapKeylist(authorizationMap)

			// each auth rule from the output should also exist in Azure
			require.Equal(goTest, len(*authNamesFromOutput), len(*AuthRulesFromAzure))
			for _, authName := range *authNamesFromOutput {
				require.Contains(goTest, *AuthRulesFromAzure, authName)
			}
		}

	}
}

// validate list of authentication rules  for the created topic
func verifyNamespaceAuthenticationRuleList(subscriptionID, resourceGroupOutputName, namespaceOutputName, namespaceAuthOutputName string) func(goTest *testing.T, output infratests.TerraformOutput) {
	return func(goTest *testing.T, output infratests.TerraformOutput) {
		namespaceAuthsMap := output[namespaceAuthOutputName].(map[string]interface{})
		resourceGroupName := output[resourceGroupOutputName].(string)

		namespaceName := output[namespaceOutputName].(string)

		for authName := range namespaceAuthsMap {
			AuthRulesFromAzure := azure.ListNamespaceAuthRules(
				goTest,
				subscriptionID,
				namespaceName,
				resourceGroupName)

			// auth rule from the output should also exist in Azure
			require.Contains(goTest, *AuthRulesFromAzure, authName)
		}
	}
}

func getMapKeylist(authorizationMap map[string]interface{}) *[]string {
	names := make([]string, 0)
	for key := range authorizationMap {
		names = append(names, key)
	}
	return &names
}
