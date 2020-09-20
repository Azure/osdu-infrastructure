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

/*
.Synopsis
   Terraform Output Configuration
.DESCRIPTION
   This file holds the Output Configuration
*/


#-------------------------------
# Output Variables
#-------------------------------
output "services_resource_group_name" {
  description = "The name of the resource group containing the data specific resources"
  value       = azurerm_resource_group.main.name
}

output "services_resource_group_id" {
  description = "The resource id for the provisioned resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "The resource id of the storage account instance"
  value       = module.storage_account.id
}

output "storage_containers" {
  description = "Map of storage account containers."
  value       = module.storage_account.containers
}

output "storage_shares" {
  description = "Map of storage account shares."
  value       = module.storage_account.shares
}

output "storage_queues" {
  description = "Map of storage account queues."
  value       = module.storage_account.queues
}

// Network Output Items for Integration Tests
output "appgw_name" {
  description = "Application gateway's name"
  value       = module.appgateway.name
}

output "keyvault_secret_id" {
  description = "The keyvault certificate keyvault resource id used to setup ssl termination on the app gateway."
  value       = azurerm_key_vault_certificate.default.0.secret_id
}


// Redis Output Items for Integration Tests
output "redis_name" {
  description = "The name of the redis_cache"
  value       = module.redis_cache.name
}

output "redis_hostname" {
  value = module.redis_cache.hostname
}

output "redis_primary_access_key" {
  value = module.redis_cache.primary_access_key
}

output "redis_ssl_port" {
  value = module.redis_cache.ssl_port
}