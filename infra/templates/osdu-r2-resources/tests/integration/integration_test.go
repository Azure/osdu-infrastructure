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
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	cosmosIntegTests "github.com/microsoft/cobalt/infra/modules/providers/azure/cosmosdb/tests/integration"
	sbIntegTests "github.com/microsoft/cobalt/infra/modules/providers/azure/service-bus/tests/integration"
	storageIntegTests "github.com/microsoft/cobalt/infra/modules/providers/azure/storage-account/tests/integration"
	esIntegTestConfig "github.com/microsoft/cobalt/infra/modules/providers/elastic/elastic-cloud-enterprise/tests"
	esIntegTests "github.com/microsoft/cobalt/infra/modules/providers/elastic/elastic-cloud-enterprise/tests/integration"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var subscription = os.Getenv("ARM_SUBSCRIPTION_ID")
var tfOptions = &terraform.Options{
	TerraformDir: "../../",
	BackendConfig: map[string]interface{}{
		"storage_account_name": os.Getenv("TF_VAR_remote_state_account"),
		"container_name":       os.Getenv("TF_VAR_remote_state_container"),
	},
}

// Runs a suite of test assertions to validate that a provisioned set of app services
// are fully funtional.
func TestAppSvcPlanSingleRegion(t *testing.T) {
	esIntegTestConfig.ESVersion = "6.8.3"
	testFixture := infratests.IntegrationTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		ExpectedTfOutputCount: 28,
		TfOutputAssertions: []infratests.TerraformOutputValidation{
			verifyAppServiceConfig,
			/* Now that we configured the services to run as Java containers via linux_fx_version,
			we'll have to temporarily comment out the call to verifyAppServiceEndpointStatusCode...
			The service(s) will be unresponsive until our Azure Pipeline deploys a jar
			to the target app service. We'll remove the comment once our service CI/CD pipelines are in place.
			verifyAppServiceEndpointStatusCode,
			*/
			verifyServicePrincipalRoleAssignments,
			esIntegTests.ValidateElasticKvSecretValues("keyvault_secret_attributes", "elastic_cluster_properties"),
			esIntegTests.CheckClusterHealth("elastic_cluster_properties"),
			esIntegTests.CheckClusterVersion("elastic_cluster_properties"),
			esIntegTests.CheckClusterIndexing("elastic_cluster_properties"),
			storageIntegTests.InspectStorageAccount("storage_account", "storage_account_containers", "resource_group"),
			sbIntegTests.VerifySubscriptionsList(subscription,
				"resource_group",
				"sb_namespace_name",
				"sb_topics"),
			cosmosIntegTests.InspectProvisionedCosmosDBAccount("resource_group", "cosmosdb_account_name", "cosmosdb_properties"),
		},
	}
	infratests.RunIntegrationTests(&testFixture)
}
