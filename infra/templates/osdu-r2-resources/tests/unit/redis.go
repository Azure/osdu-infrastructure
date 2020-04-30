package test

import (
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
)

func appendRedisTests(t *testing.T, description infratests.ResourceDescription) {
	v := asMap(t, `{
		"sku_name":                   "Standard",
		"shard_count":                0
	}`)

	k := "module.cache.azurerm_redis_cache.arc"
	description[k] = v
}
