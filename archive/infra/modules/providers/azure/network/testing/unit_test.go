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
	"encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var name = "network-"
var location = "eastus"
var count = 9

var tfOptions = &terraform.Options{
	TerraformDir: "./",
	Upgrade:      true,
}

func asMap(t *testing.T, jsonString string) map[string]interface{} {
	var theMap map[string]interface{}
	if err := json.Unmarshal([]byte(jsonString), &theMap); err != nil {
		t.Fatal(err)
	}
	return theMap
}

func TestTemplate(t *testing.T) {

	expectedResult := asMap(t, `{
		"address_space": ["10.0.1.0/24"],
		"dns_servers": ["8.8.8.8"]
	}`)

	expectedSubnet0 := asMap(t, `{
		"name": "Web-Tier",
		"address_prefixes": [
			"10.0.1.0/26"
		]
	}`)

	expectedSubnet1 := asMap(t, `{
		"address_prefixes": [
			"10.0.1.64/26"
		]
	}`)

	expectedSubnet2 := asMap(t, `{
		"address_prefixes": [
			"10.0.1.128/26"
		]
	}`)

	expectedSubnet3 := asMap(t, `{
		"address_prefixes": [
			"10.0.1.192/27"
		]
	}`)

	expectedSubnet4 := asMap(t, `{
		"name": "GatewaySubnet",
		"address_prefixes": [
			"10.0.1.224/28"
		]
	}`)

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             name + random.UniqueId(),
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.network.azurerm_virtual_network.main": expectedResult,
			"module.network.azurerm_subnet.main[0]":       expectedSubnet0,
			"module.network.azurerm_subnet.main[1]":       expectedSubnet1,
			"module.network.azurerm_subnet.main[2]":       expectedSubnet2,
			"module.network.azurerm_subnet.main[3]":       expectedSubnet3,
			"module.network.azurerm_subnet.main[4]":       expectedSubnet4,
		},
	}

	infratests.RunUnitTests(&testFixture)
}
