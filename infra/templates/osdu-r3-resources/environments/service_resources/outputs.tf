#-------------------------------
# Output Variables  (output.tf)
#-------------------------------
output "services_resource_group_name" {
  description = "The name of the resource group containing the data specific resources"
  value       = azurerm_resource_group.main.name
}

output "app_gw_name" {
  description = "Application gateway's name"
  value       = module.appgateway.name
}

output "keyvault_secret_id" {
  description = "The keyvault certificate keyvault resource id used to setup ssl termination on the app gateway."
  value       = azurerm_key_vault_certificate.default.0.secret_id
}