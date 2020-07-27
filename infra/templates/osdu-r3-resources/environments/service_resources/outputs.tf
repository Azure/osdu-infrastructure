#-------------------------------
# Output Variables  (output.tf)
#-------------------------------
output "services_resource_group_name" {
  description = "The name of the resource group containing the data specific resources"
  value       = azurerm_resource_group.main.name
}

output "keyvault_secret_id" {
  description = "The keyvault certificate keyvault resource id used to setup ssl termination on the app gateway."
  value       = azurerm_key_vault_certificate.default.0.secret_id
}

output "appgw_name" {
  description = "Application gateway's name"
  value       = module.appgateway.name
}

output "appgw_identity_id" {
  description = "Application Gateway Identity Resource Id"
  value       = azurerm_user_assigned_identity.appgw.id
}

output "appgw_identity_client_id" {
  description = "Application Gateway Identity Client Id"
  value       = azurerm_user_assigned_identity.appgw.principal_id
}

output "aks_name" {
  description = "The Kubernetes Cluster Name"
  value = module.aks-gitops.cluster_name
}

output "aks_identity_id" {
  description = "AKS Identity Resource Id"
  value = azurerm_user_assigned_identity.aks.id
}

output "aks_identity_client_id" {
  description = "AKS Identity Client Id"
  value = azurerm_user_assigned_identity.aks.principal_id
}

# output "aks_kube_config" {
#   description = "The Kubernetes Config Block"
#   value = module.aks-gitops.kube_config
# }