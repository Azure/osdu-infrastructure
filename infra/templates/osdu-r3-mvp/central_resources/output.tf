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
output "central_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "container_registry_id" {
  description = "The resource identifier of the container registry."
  value       = module.container_registry.container_registry_id
}

output "container_registry_name" {
  description = "The name of the container registry."
  value       = module.container_registry.container_registry_name
}

output "keyvault_id" {
  description = "The resource id for Key Vault"
  value       = module.keyvault.keyvault_id
}

output "keyvault_name" {
  description = "The name for Key Vault"
  value       = module.keyvault.keyvault_name
}

output "log_analytics_id" {
  description = "The resource id for Log Analytics"
  value       = module.log_analytics.id
}

output "osdu_identity_id" {
  description = "The resource id for the User Assigned Identity"
  value       = azurerm_user_assigned_identity.osduidentity.id
}

output "osdu_identity_principal_id" {
  description = "The principal id for the User Assigned Identity"
  value       = azurerm_user_assigned_identity.osduidentity.principal_id
}

output "osdu_identity_client_id" {
  description = "The client id for the User Assigned Identity"
  value       = azurerm_user_assigned_identity.osduidentity.client_id
}

output "principal_objectId" {
  description = "The service principal application object id"
  value       = var.principal_objectId
}

output "elasticsearch_endpoint" {
  description = "The elastic search endpoint"
  value       = var.elasticsearch_endpoint
}

output "elasticsearch_username" {
  description = "The elastic search username"
  value       = var.elasticsearch_username
}
