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

locals {
  throughput = 400
  cosmos_database = {
    name       = local.cosmos_db_name
    throughput = local.throughput
  }

  cosmos_sql_collections = [
    {
      name               = "LegalTag"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "StorageRecord"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "StorageSchema"
      database_name      = local.cosmos_db_name
      partition_key_path = "/kind"
      throughput         = local.throughput
    },
    {
      name               = "TenantInfo"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "UserInfo"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    }
  ]
}

module "storage_account" {
  source = "../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.app_rg.name
  container_names     = var.storage_containers
}

module "function_storage" {
  source = "../../modules/providers/azure/storage-account"

  name                = local.function_storage_name
  resource_group_name = azurerm_resource_group.app_rg.name
  container_names     = []
}

module "cache" {
  source              = "../../modules/providers/azure/redis-cache"
  name                = local.cache_name
  resource_group_name = azurerm_resource_group.app_rg.name
}

module "cosmosdb_account" {
  source                   = "../../modules/providers/azure/cosmosdb"
  name                     = local.cosmosdb_name
  resource_group_name      = azurerm_resource_group.app_rg.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = "Session"
  databases                = [local.cosmos_database]
  sql_collections          = local.cosmos_sql_collections
}
