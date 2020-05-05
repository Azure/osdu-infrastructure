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

resource "azurerm_resource_group" "storage_rg" {
  name     = local.data_rg_name
  location = var.resource_group_location
}

resource "azurerm_management_lock" "data_rg_lock" {
  name       = "osdu_storage_rg_lock"
  scope      = azurerm_resource_group.storage_rg.id
  lock_level = "CanNotDelete"
}

module "storage_account" {
  source = "../../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.storage_rg.name
  container_names     = var.storage_containers
}

module "cache" {
  source              = "../../../../modules/providers/azure/redis-cache"
  name                = local.cache_name
  resource_group_name = azurerm_resource_group.storage_rg.name
}

module "cosmosdb_account" {
  source                   = "../../../../modules/providers/azure/cosmosdb"
  name                     = local.cosmosdb_name
  resource_group_name      = azurerm_resource_group.storage_rg.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = "Session"
  databases                = [local.cosmos_database]
  sql_collections          = local.cosmos_sql_collections
}

resource "azurerm_management_lock" "cosmos_lock" {
  name       = "osdu_storage_cosmos_lock"
  scope      = module.cosmosdb_account.properties.cosmosdb.id
  lock_level = "CanNotDelete"
}

resource "azurerm_management_lock" "storage_acct_lock" {
  name       = "osdu_storage_acct_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}

resource "azurerm_management_lock" "storage_cache_lock" {
  name       = "osdu_storage_cache_lock"
  scope      = module.cache.id
  lock_level = "CanNotDelete"
}
