output "appgateway_name" {
  description = "The name of the Application Gateway created"
  value       = azurerm_application_gateway.appgateway.name
}

output "appgateway_id" {
  description = "The resource id of the Application Gateway created"
  value       = azurerm_application_gateway.appgateway.id
}

output "appgateway_ipconfig" {
  description = "The Application Gateway IP Configuration"
  value       = azurerm_application_gateway.appgateway.gateway_ip_configuration
}

output "appgateway_frontend_ip_configuration" {
  description = "The Application Gateway Frontend IP Configuration"
  value       = azurerm_application_gateway.appgateway.frontend_ip_configuration
}

output "managed_identity_resource_id" {
  description = "The resource id of the managed user identity"
  value       = azurerm_user_assigned_identity.app_gw_user_identity.id
}

output "managed_identity_principal_id" {
  description = "The resource id of the managed user identity"
  value       = azurerm_user_assigned_identity.app_gw_user_identity.principal_id
}
