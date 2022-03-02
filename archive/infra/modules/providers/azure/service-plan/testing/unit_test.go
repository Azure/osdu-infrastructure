package test

import (
	"encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var name = "service-plan"
var location = "eastus"
var count = 5

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
    "kind": "Linux",
    "reserved": true,
    "sku": [{
      "capacity": 1,
      "size": "S1",
      "tier": "Standard"
    }]
	}`)

	expectedScaling := asMap(t, `{
		"enabled": true,
		"notification": [{
      "email": [{
				"send_to_subscription_administrator": true
			}]
		}],
		"profile": [{
			"name": "Scaling Profile",
			"capacity": [{
				"default": 1,
				"minimum": 1
			}],
			"rule": [{
				"metric_trigger": [{
					"metric_name": "CpuPercentage",
					"operator": "GreaterThan",
					"statistic": "Average",
					"threshold": 70,
					"time_aggregation": "Average",
					"time_grain": "PT1M",
					"time_window": "PT5M"
				},
				{
					"metric_name": "CpuPercentage",
					"operator": "GreaterThan",
					"statistic": "Average",
					"time_aggregation": "Average",
					"time_grain": "PT1M",
					"time_window": "PT5M"
				}]
			}]
		}]
	}`)

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             name + random.UniqueId(),
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.service_plan.azurerm_app_service_plan.svcplan":                         expectedResult,
			"module.service_plan.azurerm_monitor_autoscale_setting.app_service_auto_scale": expectedScaling,
		},
	}

	infratests.RunUnitTests(&testFixture)
}
