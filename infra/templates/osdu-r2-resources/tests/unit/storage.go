package test

import (
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
)

func appendStorageTests(t *testing.T, description infratests.ResourceDescription) {

	expectedStorageAccount := asMap(t, `{
    "account_kind": "StorageV2",
    "account_replication_type": "LRS",
    "account_tier": "Standard"
	}`)
	description["module.storage_account.azurerm_storage_account.main"] = expectedStorageAccount

	expectedStorageContainer := asMap(t, `{
    "container_access_type": "private",
    "name": "data"
	}`)
	description["module.storage_account.azurerm_storage_container.main[0]"] = expectedStorageContainer

	expectedCosmosDBAccount := asMap(t, `{
    "enable_automatic_failover": true,
    "enable_multiple_write_locations": false,
	"kind": "GlobalDocumentDB",
	"offer_type": "Standard"
	}`)
	description["module.cosmosdb_account.azurerm_cosmosdb_account.cosmosdb"] = expectedCosmosDBAccount

}
