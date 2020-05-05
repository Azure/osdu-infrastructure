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

output "storage_account_containers" {
  description = "Map of storage account containers."
  value       = module.storage_account.containers
}

output "redis_hostname" {
  description = "The hostname of the redis cluster"
  value       = module.cache.hostname
}

output "elastic_cluster_properties" {
  description = "Cluster properties of the provisioned Elasticsearch cluster"
  value       = module.elastic_cluster.cluster_properties
  sensitive   = true
}

output "storage_account" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "The resource identifier of the storage account."
  value       = module.storage_account.id
}

output "cosmosdb_properties" {
  description = "Properties of the deployed CosmosDB account."
  value       = module.cosmosdb_account.properties
}

output "cosmosdb_account_name" {
  description = "The name of the CosmosDB account."
  value       = module.cosmosdb_account.account_name
}

output "redis_port" {
  description = "The ssl port of the redis cluster"
  value       = module.cache.ssl_port
}

output "redis_primary_access_key" {
  description = "The primary access key of the redis cluster"
  value       = module.cache.primary_access_key
  sensitive   = true
}

output "redis_name" {
  description = "The resource name of the redis cluster"
  value       = module.cache.name
}

output "redis_resource_id" {
  description = "The resource identifier of the redis cluster"
  value       = module.cache.id
}

output "data_resource_group_name" {
  description = "The name of the resource group containing the data specific resources"
  value       = azurerm_resource_group.storage_rg.name
}