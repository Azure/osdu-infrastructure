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

func appendServicebusTests(t *testing.T, description infratests.ResourceDescription) {

	description["module.service_bus.azurerm_servicebus_subscription.subscription[0]"] = asMap(t, `{
		"name":                                 "recordstopicsubscription",
		"dead_lettering_on_message_expiration": true
	}`)

	description["module.service_bus.azurerm_servicebus_subscription.subscription[4]"] = asMap(t, `{
		"name":                                 "indexing-progresssubscription",
		"dead_lettering_on_message_expiration": true,
		"max_delivery_count":                   5
	}`)

	description["module.service_bus.azurerm_servicebus_topic.sptopic[0]"] = asMap(t, `{
		"name":                         "recordstopic",
		"enable_partitioning":          false,
		"requires_duplicate_detection": true,
		"support_ordering":             true
	}`)

	description["module.service_bus.azurerm_servicebus_topic.sptopic[3]"] = asMap(t, `{
		"name":                         "indexing-progress",
		"enable_partitioning":          false,
		"requires_duplicate_detection": true,
		"support_ordering":             true
	}`)
}
