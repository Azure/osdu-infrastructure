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
   Terraform Main Control
.DESCRIPTION
   This file holds the main control.
*/

// *** WARNING  ****
// This template includes locks and won't delete by destroy if locks aren't removed first.
// Lock: KeyVault
// Lock: Container Registry
// *** WARNING  ****

terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}

#-------------------------------
# Providers
#-------------------------------
provider "azurerm" {
  version = "=2.29.0"
  features {}
}

provider "azuread" {
  version = "=1.0.0"
}

provider "random" {
  version = "~>2.2"
}



#-------------------------------
# Private Variables
#-------------------------------
locals {
  // sanitize names
  prefix    = replace(trimspace(lower(var.prefix)), "_", "-")
  workspace = replace(trimspace(lower(terraform.workspace)), "-", "")
  suffix    = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""

  // base prefix for resources, prefix constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  resource_group_name = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  retention_policy    = var.log_retention_days == 0 ? false : true

  kv_name                 = "${local.base_name_21}-kv"
  storage_name            = "${replace(local.base_name_21, "-", "")}tbl"
  container_registry_name = "${replace(local.base_name_21, "-", "")}cr"
  osdupod_identity_name   = "${local.base_name}-osdu-identity"
  ai_name                 = "${local.base_name}-ai"
  logs_name               = "${local.base_name}-logs"
  ad_app_name             = "${local.base_name}-app"

  rbac_contributor_scopes = concat(
    [module.container_registry.container_registry_id],
    [module.keyvault.keyvault_id]
  )
  role = "Contributor"
  rbac_principals = [
    azurerm_user_assigned_identity.osduidentity.principal_id,
    module.service_principal.id
  ]
}



#-------------------------------
# Common Resources
#-------------------------------
data "azurerm_client_config" "current" {}

resource "random_string" "workspace_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name = replace(trimspace(lower(terraform.workspace)), "-", "")
    prefix  = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = max(1, var.randomization_level) // error for zero-length
  special = false
  upper   = false
}

#-------------------------------
# Resource Group
#-------------------------------
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.resource_group_location
  tags     = var.resource_tags

  lifecycle {
    ignore_changes = [tags]
  }
}



#-------------------------------
# Key Vault
#-------------------------------
module "keyvault" {
  source = "../../../modules/providers/azure/keyvault"

  keyvault_name       = local.kv_name
  resource_group_name = azurerm_resource_group.main.name
  secrets = {
    app-dev-sp-tenant-id = data.azurerm_client_config.current.tenant_id
  }

  resource_tags = var.resource_tags
}

module "keyvault_policy" {
  source    = "../../../modules/providers/azure/keyvault-policy"
  vault_id  = module.keyvault.keyvault_id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_ids = [
    azurerm_user_assigned_identity.osduidentity.principal_id,
    module.service_principal.id
  ]
  key_permissions         = ["get"]
  certificate_permissions = ["get"]
  secret_permissions      = ["get"]
}

resource "azurerm_role_assignment" "kv_roles" {
  count = length(local.rbac_principals)

  role_definition_name = "Reader"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.keyvault.keyvault_id
}

#-------------------------------
# Storage
#-------------------------------
module "storage_account" {
  source = "../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = []
  kind                = "StorageV2"
  replication_type    = var.storage_replication_type

  resource_tags = var.resource_tags
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "storage_access" {
  count = length(local.rbac_principals)

  role_definition_name = local.role
  principal_id         = local.rbac_principals[count.index]
  scope                = module.storage_account.id
}



#-------------------------------
# Container Registry
#-------------------------------
module "container_registry" {
  source = "../../../modules/providers/azure/container-registry"

  container_registry_name = local.container_registry_name
  resource_group_name     = azurerm_resource_group.main.name

  container_registry_sku           = var.container_registry_sku
  container_registry_admin_enabled = false

  resource_tags = var.resource_tags
}



#-------------------------------
# Application Insights
#-------------------------------
module "app_insights" {
  source = "../../../modules/providers/azure/app-insights"

  appinsights_name                 = local.ai_name
  service_plan_resource_group_name = azurerm_resource_group.main.name
  appinsights_application_type     = "other"

  resource_tags = var.resource_tags
}



#-------------------------------
# Log Analytics
#-------------------------------
module "log_analytics" {
  source = "../../../modules/providers/azure/log-analytics"

  name                = local.logs_name
  resource_group_name = azurerm_resource_group.main.name

  solutions = [
    {
      solution_name = "ContainerInsights",
      publisher     = "Microsoft",
      product       = "OMSGallery/ContainerInsights",
    },
    {
      solution_name = "KeyVaultAnalytics",
      publisher     = "Microsoft",
      product       = "OMSGallery/KeyVaultAnalytics",
    },
    {
      solution_name = "AzureAppGatewayAnalytics",
      publisher     = "Microsoft",
      product       = "OMSGallery/AzureAppGatewayAnalytics",
    }
  ]

  resource_tags = var.resource_tags
}



#-------------------------------
# AD Principal and Applications
#-------------------------------
module "service_principal" {
  source = "../../../modules/providers/azure/service-principal"

  name   = var.principal_name
  scopes = local.rbac_contributor_scopes
  role   = "Contributor"

  create_for_rbac = false
  object_id       = var.principal_objectId

  principal = {
    name     = var.principal_name
    appId    = var.principal_appId
    password = var.principal_password
  }
}


module "ad_application" {
  source                     = "../../../modules/providers/azure/ad-application"
  name                       = local.ad_app_name
  oauth2_allow_implicit_flow = true

  reply_urls = [
    "http://localhost:8080",
    "http://localhost:8080/auth/callback"
  ]

  api_permissions = [
    {
      name = "Microsoft Graph"
      oauth2_permissions = [
        "User.Read"
      ]
    }
  ]
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
// Identity for OSDU Pod Identity
resource "azurerm_user_assigned_identity" "osduidentity" {
  name                = local.osdupod_identity_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = var.resource_tags
}



#-------------------------------
# Locks
#-------------------------------

// Lock the KV
resource "azurerm_management_lock" "kv_lock" {
  name       = "osdu_cr_kv_lock"
  scope      = module.keyvault.keyvault_id
  lock_level = "CanNotDelete"
}

// Lock the Storage
resource "azurerm_management_lock" "sa_lock" {
  name       = "osdu_tbl_sa_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}

// Lock the Container Registry
resource "azurerm_management_lock" "acr_lock" {
  name       = "osdu_acr_lock"
  scope      = module.container_registry.container_registry_id
  lock_level = "CanNotDelete"
}
