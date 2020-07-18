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

data "azuread_service_principal" "flexvol" {
  application_id = var.service_principal_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "flexvol" {
  count = var.enable_flexvol && var.service_principal_id != data.azurerm_client_config.current.client_id ? 1 : 0

  principal_id         = data.azuread_service_principal.flexvol.id
  role_definition_name = var.flexvol_role_assignment_role
  scope                = "/subscriptions/${var.subscription_id}/resourcegroups/${var.resource_group_name}/providers/Microsoft.KeyVault/vaults/${var.keyvault_name}"
}