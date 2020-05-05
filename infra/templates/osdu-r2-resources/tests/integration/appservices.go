//  Copyright � Microsoft Corporation
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
	httpClient "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/microsoft/cobalt/test-harness/infratests"
	"github.com/microsoft/cobalt/test-harness/terratest-extensions/modules/azure"
	"github.com/stretchr/testify/require"
	"strings"
	"testing"
)

// Verifies that the provisioned webapp is properly configured.
func verifyAppServiceConfig(goTest *testing.T, output infratests.TerraformOutput) {
	resourceGroup := output["resource_group"].(string)

	for _, appName := range output["app_service_names"].([]interface{}) {
		appConfig := azure.WebAppSiteConfiguration(goTest, subscription, resourceGroup, appName.(string))
		linuxFxVersion := strings.Trim(*appConfig.LinuxFxVersion, "{}")
		expectedLinuxFxVersion := "JAVA|8-jre8"
		require.Equal(goTest, expectedLinuxFxVersion, linuxFxVersion)
	}
}

// Verifies that the provisioned webapp is properly configured.
func verifyAppServiceEasyAuth(goTest *testing.T, output infratests.TerraformOutput) {
	resourceGroup := output["resource_group"].(string)
	adApplicationConfig := output["azuread_app_ids"].([]interface{})

	for _, appName := range output["app_service_names"].([]interface{}) {
		var clientID string = *azure.WebAppEasyAuthClientID(goTest, subscription, resourceGroup, appName.(string))
		require.NotNil(goTest, clientID)
		require.True(goTest, arrayContains(adApplicationConfig, clientID))
	}
}

// Verifies that the provisioned webapp is properly configured.
func verifyAppServiceEndpointStatusCode(goTest *testing.T, output infratests.TerraformOutput) {
	for _, fqdn := range output["app_service_fqdns"].([]interface{}) {
		require.True(goTest, httpGetRespondsWithCode(goTest, fqdn.(string), 401))
	}
}

// Verifies that the provisioned webapp is properly configured.
func verifyFunctionAppEndpointStatusCode(goTest *testing.T, output infratests.TerraformOutput) {
	for _, fqdn := range output["function_app_fqdns"].([]interface{}) {
		require.True(goTest, httpGetRespondsWithCode(goTest, fqdn.(string), 403))
	}
}

// Validates that the service responds with provided HTTP Code.
func httpGetRespondsWithCode(goTest *testing.T, url string, code int) bool {
	statusCode, _, err := httpClient.HttpGetE(goTest, url)
	if err != nil {
		goTest.Fatal(err)
	}

	return statusCode == code
}

func arrayContains(arr []interface{}, str string) bool {
	for _, a := range arr {
		if a == str {
			return true
		}
	}
	return false
}
