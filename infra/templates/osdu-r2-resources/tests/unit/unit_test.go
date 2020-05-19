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
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var tfOptions = &terraform.Options{
	TerraformDir: "../../",
	Upgrade:      true,
	Vars: map[string]interface{}{
		"resource_group_location": region,
		"prefix":                  prefix,
		"app_services": []interface{}{
			map[string]interface{}{
				"app_name":         "tf-test-svc-1",
				"image":            *new(string),
				"linux_fx_version": "JAVA|8-jre8",
				"app_command_line": *new(string),
				"app_settings":     make(map[string]string, 0),
			},
		},
	},
	BackendConfig: map[string]interface{}{
		"storage_account_name": os.Getenv("TF_VAR_remote_state_account"),
		"container_name":       os.Getenv("TF_VAR_remote_state_container"),
	},
}

func TestTemplate(t *testing.T) {
	expectedAppDevResourceGroup := asMap(t, `{
		"location": "`+region+`"
	}`)

	expectedAppInsights := asMap(t, `{
		"application_type":    "Web"
	}`)

	resourceDescription := infratests.ResourceDescription{
		"azurerm_resource_group.app_rg":                                expectedAppDevResourceGroup,
		"module.app_insights.azurerm_application_insights.appinsights": expectedAppInsights,
	}

	appendAppServiceTests(t, resourceDescription)
	appendAutoScaleTests(t, resourceDescription)
	appendKeyVaultTests(t, resourceDescription)
	appendStorageTests(t, resourceDescription)
	appendFunctionAppTests(t, resourceDescription)
	appendServicebusTests(t, resourceDescription)

	testFixture := infratests.UnitTestFixture{
		GoTest:                          t,
		TfOptions:                       tfOptions,
		Workspace:                       workspace,
		PlanAssertions:                  nil,
		ExpectedResourceCount:           101,
		ExpectedResourceAttributeValues: resourceDescription,
	}

	infratests.RunUnitTests(&testFixture)
}
