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
   Terraform Security Control
.DESCRIPTION
   This file holds security settings.
*/


#-------------------------------
# Private Variables
#-------------------------------
locals {
  ai_key_name = "appinsights-key"

  logs_id_name  = "log-workspace-id"
  logs_key_name = "log-workspace-key"
}



#-------------------------------
# Application Insights
#-------------------------------
resource "azurerm_key_vault_secret" "insights" {
  name         = local.ai_key_name
  value        = module.app_insights.app_insights_instrumentation_key
  key_vault_id = module.keyvault.keyvault_id
}



#-------------------------------
# Log Analytics
#-------------------------------
resource "azurerm_key_vault_secret" "workspace_id" {
  name         = local.logs_id_name
  value        = module.log_analytics.log_workspace_id
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "workspace_key" {
  name         = local.logs_key_name
  value        = module.log_analytics.log_workspace_key
  key_vault_id = module.keyvault.keyvault_id
}


#-------------------------------
# AD Principal and Applications
#-------------------------------
resource "azurerm_key_vault_secret" "principal_id" {
  name         = "app-dev-sp-username"
  value        = module.service_principal.client_id
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "principal_secret" {
  name         = "app-dev-sp-password"
  value        = module.service_principal.client_secret
  key_vault_id = module.keyvault.keyvault_id
}
