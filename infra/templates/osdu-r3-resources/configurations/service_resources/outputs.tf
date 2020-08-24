#-------------------------------
# Output Variables  (output.tf)
#-------------------------------
output "services_resource_group_name" {
  description = "The name of the resource group containing the data specific resources"
  value       = azurerm_resource_group.main.name
}

output "services_resource_group_id" {
  description = "The resource id for the provisioned resource group"
  value       = azurerm_resource_group.main.id
}

output "keyvault_secret_id" {
  description = "The keyvault certificate keyvault resource id used to setup ssl termination on the app gateway."
  value       = azurerm_key_vault_certificate.default.0.secret_id
}

output "appgw_name" {
  description = "Application gateway's name"
  value       = module.appgateway.name
}

output "appgw_id" {
  description = "Application gateway's name"
  value       = module.appgateway.id
}

output "appgw_managed_identity_resource_id" {
  description = "The resource id of the managed user identity"
  value       = module.appgateway.managed_identity_resource_id
}

output "agic_identity_id" {
  description = "Application Gateway Identity Resource Id"
  value       = azurerm_user_assigned_identity.agicidentity.id
}

output "agic_identity_client_id" {
  description = "Application Gateway Identity Client Id"
  value       = azurerm_user_assigned_identity.agicidentity.client_id
}

output "agic_identity_principal_id" {
  description = "Application gateway ingress controller's user identity principal id"
  value       = azurerm_user_assigned_identity.agicidentity.principal_id
}

output "storage_account_id" {
  description = "The resource id of the ADLS Gen 2 storage account instance"
  value       = data.terraform_remote_state.data_resources.outputs.storage_account_id
}

output "keyvault_id" {
  description = "The resource id for Key Vault"
  value       = module.keyvault.keyvault_id
}

output "cosmosdb_account_id" {
  description = "The resource id of the CosmosDB instance"
  value       = data.terraform_remote_state.data_resources.outputs.cosmosdb_account_id
}

output "container_registry_id" {
  description = "The resource id of the ACR container instance"
  value       = data.terraform_remote_state.common_resources.outputs.container_registry_id
}

output "aks_name" {
  description = "The Kubernetes Cluster Name"
  value       = module.aks-gitops.cluster_name
}

output "aks_principal_id" {
  description = "AKS Cluster Service Principal Id"
  value       = module.aks-gitops.cluster_principal_id
}

output "aks_kubelet_object_id" {
  description = "The principal object identifier for the aks cluster's kubelet identity"
  value       = module.aks-gitops.kubelet_object_id
}

output "aks_node_resource_group_id" {
  description = "The aks cluster vmss node resource group identifier"
  value       = data.azurerm_resource_group.aks_node_resource_group.id
}

output "aks_pod_identity_namespace" {
  description = "AAD pod identity kubernetes namespace"
  value       = local.helm_pod_identity_ns
}

output "aad_pod_identity_id" {
  description = "AKS Pod Identity Resource Id"
  value       = azurerm_user_assigned_identity.podidentity.id
}

output "aad_pod_identity_client_id" {
  description = "AKS Pod Identity Client Id"
  value       = azurerm_user_assigned_identity.podidentity.client_id
}

output "aad_osdu_identity_id" {
  description = "The resource id for the aad pod managed identity"
  value       = azurerm_user_assigned_identity.osduidentity.id
}

output "aad_osdu_identity_client_id" {
  description = "The resource id for the aad pod managed identity"
  value       = azurerm_user_assigned_identity.osduidentity.client_id
}

output "aad_osdu_identity_object_id" {
  description = "The resource id for the aad pod managed identity"
  value       = azurerm_user_assigned_identity.osduidentity.principal_id
}

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
