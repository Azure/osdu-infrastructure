package test

import (
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
)

func appendFunctionAppTests(t *testing.T, description infratests.ResourceDescription) {

	expectedFunctionStorage := asMap(t, `{
    "account_kind": "StorageV2",
    "account_replication_type": "LRS",
    "account_tier": "Standard"
	}`)
	description["module.function_storage.azurerm_storage_account.main"] = expectedFunctionStorage

	expectedContainerRegistry := asMap(t, `{
    "admin_enabled":  false,
    "sku":  "Standard"
	}`)
	description["module.container_registry.azurerm_container_registry.container_registry"] = expectedContainerRegistry

	expectedFunctionApp := asMap(t, `{
    "version":  "~2",
    "site_config": [{
      "always_on":         true,
      "linux_fx_version":  "DOCKER"
		}]
	}`)
	description["module.function_app.azurerm_function_app.main[0]"] = expectedFunctionApp
}
