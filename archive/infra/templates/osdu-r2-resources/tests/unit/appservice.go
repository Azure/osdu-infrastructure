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
)

func appendAppServiceTests(t *testing.T, description infratests.ResourceDescription) {

	expectedAppServicePlan := asMap(t, `{
		"kind":                       "Linux",
		"reserved":                   true,
		"sku": [{ "capacity": 1, "size": "P3v2", "tier": "PremiumV2" }]
	}`)
	description["module.service_plan.azurerm_app_service_plan.svcplan"] = expectedAppServicePlan

	expectedAppService := asMap(t, `{
		"identity":    [{ "type": "SystemAssigned" }],
		"enabled":     true,
		"site_config": [{
			"always_on":         true
		}]
	}`)
	description["module.authn_app_service.azurerm_app_service.appsvc[0]"] = expectedAppService

	expectedAppServiceSlot := asMap(t, `{
		"name":        "staging",
		"identity":    [{ "type": "SystemAssigned" }],
		"enabled":     true,
		"site_config": [{
			"always_on":         true
		}]
	}`)
	description["module.authn_app_service.azurerm_app_service_slot.appsvc_staging_slot[0]"] = expectedAppServiceSlot
}
