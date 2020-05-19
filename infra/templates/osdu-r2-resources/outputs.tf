//  Copyright � Microsoft Corporation
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

output "app_service_fqdns" {
  value = [
    for uri in module.authn_app_service.app_service_uris :
    "https://${uri}"
  ]
}

output "function_app_fqdns" {
  value = [
    for uri in module.function_app.uris :
    "https://${uri}"
  ]
}

output "app_service_msi_object_ids" {
  value = module.authn_app_service.app_service_identity_object_ids
}

output "app_service_config" {
  value = module.authn_app_service.app_service_config_data
}

output "app_service_names" {
  value = module.authn_app_service.app_service_names
}

output "app_service_ids" {
  value = module.authn_app_service.app_service_ids
}

output "service_plan_name" {
  value = module.service_plan.service_plan_name
}

output "service_plan_id" {
  value = module.service_plan.app_service_plan_id
}

output "resource_group" {
  value = azurerm_resource_group.app_rg.name
}

output "azuread_app_ids" {
  value = module.ad_application.azuread_app_ids
}

output "contributor_service_principal_id" {
  description = "ID of the service principal with contributor access to provisioned resources"
  value       = module.app_management_service_principal.service_principal_object_id
}

output "keyvault_uri" {
  description = "The uri of the keyvault"
  value       = module.keyvault.keyvault_uri
}

output "keyvault_secret_attributes" {
  description = "The properties of all provisioned keyvault secrets"
  value = {
    for secret in module.keyvault_secrets.keyvault_secret_attributes :
    secret.name => {
      id      = secret.id
      value   = secret.value
      version = secret.version
    }
  }
  sensitive = true
}

output "keyvault_name" {
  description = "The name of the keyvault"
  value       = module.keyvault.keyvault_name
}

output "storage_account" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "The resource identifier of the storage account."
  value       = module.storage_account.id
}

output "container_registry_id" {
  description = "The resource identifier of the container registry."
  value       = module.container_registry.container_registry_id
}

output "container_registry_name" {
  description = "The name of the container registry."
  value       = module.container_registry.container_registry_name
}

output "storage_account_containers" {
  description = "Map of storage account containers."
  value       = module.storage_account.containers
}

output "cosmosdb_properties" {
  description = "Properties of the deployed CosmosDB account."
  value       = module.cosmosdb_account.properties
  sensitive   = true
}

output "cosmosdb_account_name" {
  description = "The name of the CosmosDB account."
  value       = module.cosmosdb_account.account_name
}

output "cosmosdb_conn_string_kv_secret_name" {
  description = "Secret name storing the primary connection string for CosmosDB."
  value       = "cosmos-connection"
}

output "elastic_cluster_properties" {
  description = "Cluster properties of the Elasticsearch cluster. Included here for testing purposes"
  value = {
    elastic_search : {
      username = var.elasticsearch_username
      password = var.elasticsearch_password
      endpoint = var.elasticsearch_endpoint
    }
  }
  sensitive = true
}

## Service Bus output

output "sb_namespace_name" {
  description = "The service bus namespace name."
  value       = module.service_bus.namespace_name
}

output "sb_namespace_id" {
  description = "The service bus namespace id."
  value       = module.service_bus.namespace_id
}

output "sb_namespace_default_connection_string" {
  description = "The primary connection string for the Service Bus namespace authorization rule RootManageSharedAccessKey."
  value       = module.service_bus.service_bus_namespace_default_connection_string
}

output "sb_topics" {
  description = "The primary connection string for the Service Bus namespace authorization rule RootManageSharedAccessKey."
  value       = module.service_bus.topics
}

output "app_insights_instrumentation_key" {
  description = "App Insights Instrumentation Key"
  value       = module.app_insights.app_insights_instrumentation_key
}
