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

var name = "postgreSQL-"
var location = "eastus2"
var count = 11

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
		"administrator_login" : "test",
		"sku_name" : "GP_Gen5_4",
		"auto_grow_enabled" : true,
		"backup_retention_days" : 7,
		"geo_redundant_backup_enabled" : true,
		"public_network_access_enabled" : false,
		"ssl_enforcement_enabled" : true,
		"ssl_minimal_tls_version_enforced" : "TLSEnforcementDisabled",
		"version" : "10.0",
		"storage_mb" : 5120
	}`)

	expectedFirewallRule := asMap(t, `{
		"start_ip_address" : "10.0.0.2",
		"end_ip_address" : "10.0.0.8"
	}`)

	expectedConfig := asMap(t, `{
		"name" : "config",
		"value" : "test"
	}`)

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             name + random.UniqueId(),
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.postgreSQL.azurerm_postgresql_server.main":           expectedResult,
			"module.postgreSQL.azurerm_postgresql_configuration.main[0]": expectedConfig,
			"module.postgreSQL.azurerm_postgresql_firewall_rule.main[0]": expectedFirewallRule,
		},
	}

	infratests.RunUnitTests(&testFixture)
}
