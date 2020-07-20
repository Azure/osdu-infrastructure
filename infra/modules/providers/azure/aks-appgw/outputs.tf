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


output "name" {
  description = "The name of the Application Gateway created"
  value       = azurerm_application_gateway.main.name
}

output "id" {
  description = "The resource id of the Application Gateway created"
  value       = azurerm_application_gateway.main.id
}

output "ipconfig" {
  description = "The Application Gateway IP Configuration"
  value       = azurerm_application_gateway.main.gateway_ip_configuration
}

output "frontend_ip_configuration" {
  description = "The Application Gateway Frontend IP Configuration"
  value       = azurerm_application_gateway.main.frontend_ip_configuration
}

output "managed_identity_resource_id" {
  description = "The resource id of the managed user identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "managed_identity_principal_id" {
  description = "The resource id of the managed user identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}