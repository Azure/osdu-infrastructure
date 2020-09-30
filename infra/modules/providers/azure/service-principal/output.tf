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

output "id" {
  description = "The ID of the Azure AD Service Principal"
  value       = var.create_for_rbac == true ? azuread_service_principal.main[0].object_id : var.object_id
}

output "name" {
  description = "The Display Name of the Azure AD Application associated with this Service Principal"
  value       = var.create_for_rbac == true ? azuread_service_principal.main[0].display_name : var.principal.name
}

output "client_id" {
  description = "The ID of the Azure AD Application"
  value       = var.create_for_rbac == true ? azuread_service_principal.main[0].application_id : var.principal.appId
}

output "client_secret" {
  description = "The password of the generated service principal. This is only exported when create_for_rbac is true."
  value       = var.create_for_rbac == true ? azuread_service_principal_password.main[0].value : var.principal.password
  sensitive   = true
}
