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
  storage_account_name = format("tbl-storage")
  storage_key_name     = format("%s-key", local.storage_account_name)

  logs_id_name  = "log-workspace-id"
  logs_key_name = "log-workspace-key"
}


#-------------------------------
# Misc
#-------------------------------
resource "azurerm_key_vault_secret" "base_name_cr" {
  name         = "base-name-cr"
  value        = local.base_name_60
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "tenant_id" {
  name         = "tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "subscription_id" {
  name         = "subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
  key_vault_id = module.keyvault.keyvault_id
}


#-------------------------------
# Container Registry
#-------------------------------
resource "azurerm_key_vault_secret" "container_registry_name" {
  name         = "container-registry"
  value        = module.container_registry.container_registry_name
  key_vault_id = module.keyvault.keyvault_id
}


#-------------------------------
# Storage
#-------------------------------
resource "azurerm_key_vault_secret" "storage_name" {
  name         = local.storage_account_name
  value        = module.storage_account.name
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = local.storage_key_name
  value        = module.storage_account.primary_access_key
  key_vault_id = module.keyvault.keyvault_id
}



#-------------------------------
# Application Insights
#-------------------------------
resource "azurerm_key_vault_secret" "insights" {
  name         = "appinsights-key"
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

resource "azurerm_key_vault_secret" "principal_object_id" {
  name         = "app-dev-sp-id"
  value        = module.service_principal.id
  key_vault_id = module.keyvault.keyvault_id
}

// Add Application Information to KV
resource "azurerm_key_vault_secret" "application_id" {
  name         = "aad-client-id"
  value        = module.ad_application.id
  key_vault_id = module.keyvault.keyvault_id
}


#-------------------------------
# OSDU Identity
#-------------------------------

// Add Application Information to KV
resource "azurerm_key_vault_secret" "identity_id" {
  name         = "osdu-identity-id"
  value        = azurerm_user_assigned_identity.osduidentity.client_id
  key_vault_id = module.keyvault.keyvault_id
}