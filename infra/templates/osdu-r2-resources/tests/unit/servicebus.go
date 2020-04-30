package test

import (
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
)

func appendServicebusTests(t *testing.T, description infratests.ResourceDescription) {

	description["module.service_bus.azurerm_servicebus_subscription.subscription[0]"] = asMap(t, `{
		"name":                                 "recordstopicsubscription",
		"dead_lettering_on_message_expiration": true
	}`)

	description["module.service_bus.azurerm_servicebus_subscription.subscription[4]"] = asMap(t, `{
		"name":                                 "indexing-progresssubscription",
		"dead_lettering_on_message_expiration": true,
		"max_delivery_count":                   1
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
