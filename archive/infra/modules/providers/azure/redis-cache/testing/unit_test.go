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
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var workspace = "osdu-services-" + strings.ToLower(random.UniqueId())
var location = "eastus"
var count = 4

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
		"capacity" : 1,
		"enable_non_ssl_port" : false,
		"family" : "C",
		"minimum_tls_version" : "1.2",
		"shard_count" : 0,
		"sku_name" : "Standard",
		"redis_configuration" : [{
			"enable_authentication" : true,
			"maxfragmentationmemory_reserved" : 50,
			"maxmemory_delta" : 50,
			"maxmemory_policy" : "volatile-lru",
			"maxmemory_reserved" : 50
		}]
	}`)

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             workspace,
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.redis-cache.azurerm_redis_cache.arc": expectedResult,
		},
	}

	infratests.RunUnitTests(&testFixture)
}
