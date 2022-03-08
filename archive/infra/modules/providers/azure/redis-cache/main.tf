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

data "azurerm_resource_group" "arc" {
  name = var.resource_group_name
}

resource "azurerm_redis_cache" "arc" {
  name                = var.name
  location            = data.azurerm_resource_group.arc.location
  resource_group_name = var.resource_group_name
  capacity            = var.capacity
  sku_name            = var.sku_name
  family              = var.sku_name == "Premium" ? "P" : "C"
  shard_count         = var.premium_tier_config.cache_shard_count
  minimum_tls_version = var.minimum_tls_version
  tags                = var.resource_tags

  redis_configuration {
    maxmemory_reserved              = var.memory_features.maxmemory_reserved
    maxmemory_delta                 = var.memory_features.maxmemory_delta
    maxmemory_policy                = var.memory_features.maxmemory_policy
    maxfragmentationmemory_reserved = var.memory_features.maxfragmentationmemory_reserved
  }

  patch_schedule {
    day_of_week    = var.premium_tier_config.server_patch_day
    start_hour_utc = var.premium_tier_config.server_patch_hour
  }
}