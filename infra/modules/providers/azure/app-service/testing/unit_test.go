package test

import (
	"encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var name = "app-service-"
var location = "eastus"
var count = 10

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
		"enabled": true,
		"app_settings": {
			"DOCKER_REGISTRY_SERVER_URL": "https://mcr.microsoft.com",
			"DOCKER_REGISTRY_SERVER_PASSWORD": "",
			"DOCKER_REGISTRY_SERVER_USERNAME": "",
			"KEYVAULT_URI": "",
			"WEBSITES_ENABLE_APP_SERVICE_STORAGE": "false",
			"APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=secret_key",
			"ApplicationInsightsAgent_EXTENSION_VERSION": "~2",
			"iac": "terraform",
			"tf_setting": "setting1"
		},
		"site_config": [{
			"always_on": true,
			"linux_fx_version": "DOCKER|mcr.microsoft.com/azuredocs/aci-helloworld:latest"
		}]
	}`)

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             name + random.UniqueId(),
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.app_service.azurerm_app_service.appsvc[0]":                   expectedResult,
			"module.app_service.azurerm_app_service_slot.appsvc_staging_slot[0]": expectedResult,
		},
	}

	infratests.RunUnitTests(&testFixture)
}
