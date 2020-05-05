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

output "resource_group" {
  value = azurerm_resource_group.aks_rg.name
}

output "contributor_service_principal_id" {
  description = "App ID of the service principal with contributor access to provisioned resources"
  value       = module.app_management_service_principal.service_principal_application_id
}

output "elastic_cluster_properties" {
  description = "Cluster properties of the provisioned Elasticsearch cluster"
  value       = data.terraform_remote_state.data_sources.outputs.elastic_cluster_properties
  sensitive   = true
}

output "contributor_service_principal_object_id" {
  description = "Object ID of the service principal with contributor access to provisioned resources"
  value       = module.app_management_service_principal.service_principal_object_id
}

output "keyvault_uri" {
  description = "The uri of the keyvault"
  value       = module.keyvault.keyvault_uri
}

output "container_registry_id" {
  description = "The resource id of the ACR container instance"
  value       = data.terraform_remote_state.image_repository.outputs.container_registry_id
}

output "storage_account_id" {
  description = "The resource id of the ADLS Gen 2 storage account instance"
  value       = data.terraform_remote_state.data_sources.outputs.storage_account_id
}

output "redis_resource_id" {
  description = "The resource id of the Redis cache instance"
  value       = data.terraform_remote_state.data_sources.outputs.redis_resource_id
}

output "sb_namespace_id" {
  description = "The resource id of the Service Bus instance"
  value       = module.service_bus.namespace_id
}

output "vnet_id" {
  description = "The resource id for the vnet configured for AKS"
  value       = data.azurerm_virtual_network.aks_vnet.id
}

output "keyvault_id" {
  description = "The resource id for Key Vault"
  value       = module.keyvault.keyvault_id
}

output "cosmos_id" {
  description = "The resource id for Cosmos"
  value       = data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.id
}

output "resource_group_id" {
  description = "The resource id for the provisioned resource group"
  value       = azurerm_resource_group.aks_rg.id
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

## Service Bus output

output "sb_namespace_name" {
  description = "The service bus namespace name."
  value       = module.service_bus.namespace_name
}

output "sb_namespace_default_connection_string" {
  description = "The primary connection string for the Service Bus namespace authorization rule RootManageSharedAccessKey."
  value       = module.service_bus.service_bus_namespace_default_connection_string
  sensitive   = true
}

output "sb_topics" {
  description = "The primary connection string for the Service Bus namespace authorization rule RootManageSharedAccessKey."
  value       = module.service_bus.topics
}

output "app_insights_instrumentation_key" {
  description = "App Insights Instrumentation Key"
  value       = module.app_insights.app_insights_instrumentation_key
  sensitive   = true
}

output "aks_msi_client_id" {
  description = "The principal object identifier for the managed identity created for the aks cluster"
  value       = module.aks-gitops.msi_client_id
}

output "aks_kubelet_client_id" {
  description = "The principal object identifier for the aks cluster's kubelet identity"
  value       = module.aks-gitops.kubelet_client_id
}

output "aks_resource_id" {
  description = "The aks cluster resource id"
  value       = module.aks-gitops.aks_resource_id
}

output "aks_node_resource_group" {
  description = "The aks cluster vmss node resource group name"
  value       = module.aks-gitops.node_resource_group
}
