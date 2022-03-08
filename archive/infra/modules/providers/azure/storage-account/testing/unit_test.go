package test

import (
	"encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var name = "storage-"
var count = 7

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
		"account_kind" : "StorageV2",
		"account_replication_type": "LRS",
		"account_tier": "Standard"
	}`)

	expectedContainer := asMap(t, `{
		"name" : "osdu-container",
		"container_access_type": "private"
	}`)

	expectedShare := asMap(t, `{
		"name" : "osdu-share",
		"quota": 50
	}`)

	expectedQueue := asMap(t, `{
		"name" : "osdu-queue"
	}`)

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             name + random.UniqueId(),
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.storage_account.azurerm_storage_account.main":      expectedResult,
			"module.storage_account.azurerm_storage_container.main[0]": expectedContainer,
			"module.storage_account.azurerm_storage_share.main[0]":     expectedShare,
			"module.storage_account.azurerm_storage_queue.main[0]":     expectedQueue,
		},
	}

	infratests.RunUnitTests(&testFixture)
}
