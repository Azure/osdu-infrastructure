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
