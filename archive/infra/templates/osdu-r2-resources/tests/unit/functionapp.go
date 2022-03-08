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
	"github.com/microsoft/cobalt/test-harness/infratests"
	"testing"
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
