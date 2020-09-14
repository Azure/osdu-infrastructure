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
  version = "=2.26.0"
  features {}
}

provider "azuread" {
  version = "=1.0.0"
}

provider "random" {
  version = "~>2.2"
}

#-------------------------------
# Application Variables  (variables.tf)
#-------------------------------
variable "prefix" {
  description = "(Required) An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 4
}

variable "resource_group_location" {
  description = "The Azure region where container registry resources in this template should be created."
  type        = string
}

variable "container_registry_sku" {
  description = "(Optional) The SKU name of the the container registry. Possible values are Basic, Standard and Premium."
  type        = string
  default     = "Standard"
}

variable "diag_storage_containers" {
  description = "The list of storage container names to create. Names must be unique per storage account."
  type        = list(string)
  default     = []
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "endpoint for elasticsearch cluster"
}

variable "elasticsearch_username" {
  type        = string
  description = "username for elasticsearch cluster"
}

variable "elasticsearch_password" {
  type        = string
  description = "password for elasticsearch cluster"
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

#-------------------------------
# Private Variables  (common.tf)
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

  resource_group_name     = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  kv_name                 = "${local.base_name_21}-kv"
  storage_name            = "${replace(local.base_name_21, "-", "")}diag"
  storage_account_name    = "diagnostics-account"
  storage_key_name        = "${local.storage_account_name}-key"
  container_registry_name = "${replace(local.base_name_21, "-", "")}cr"
  osdupod_identity_name   = "${local.base_name}-osdu-identity"
  ai_name                 = "${local.base_name}-ai"
  ai_key_name             = "appinsights-key"
  logs_name               = "${local.base_name}-logs"
}

#-------------------------------
# Common Resources  (common.tf)
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

#-------------------------------+
# Key Vault  (security.tf)
#-------------------------------
module "keyvault" {
  source = "../../../modules/providers/azure/keyvault"

  keyvault_name       = local.kv_name
  resource_group_name = azurerm_resource_group.main.name
  secrets = {
    elastic-endpoint     = var.elasticsearch_endpoint
    elastic-username     = var.elasticsearch_username
    elastic-password     = var.elasticsearch_password
    app-dev-sp-tenant-id = data.azurerm_client_config.current.tenant_id
  }

  resource_tags = var.resource_tags
}

resource "azurerm_monitor_diagnostic_setting" "kv_diagnostics" {
  name                       = "kv_diagnostics"
  target_resource_id         = module.keyvault.keyvault_id
  log_analytics_workspace_id = module.log_analytics.id

  log {
    category = "AuditEvent"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}






#-------------------------------
# Diagnostics Storage
#-------------------------------
module "storage_account" {
  source = "../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = var.diag_storage_containers
  kind                = "StorageV2"
  replication_type    = "LRS"

  resource_tags = var.resource_tags
}


// Add the Storage Key to the Vault
resource "azurerm_key_vault_secret" "storage" {
  name         = local.storage_key_name
  value        = module.storage_account.primary_access_key
  key_vault_id = module.keyvault.keyvault_id
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

resource "azurerm_monitor_diagnostic_setting" "acr_diagnostics" {
  name                       = "acr_diagnostics"
  target_resource_id         = module.container_registry.container_registry_id
  log_analytics_workspace_id = module.log_analytics.id

  log {
    category = "ContainerRegistryRepositoryEvents"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }

  log {
    category = "ContainerRegistryLoginEvents"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}




#-------------------------------
# Application Insights (main.tf)
#-------------------------------
module "app_insights" {
  source = "../../../modules/providers/azure/app-insights"

  appinsights_name                 = local.ai_name
  service_plan_resource_group_name = azurerm_resource_group.main.name
  appinsights_application_type     = "other"

  resource_tags = var.resource_tags
}

// Add the App Insights Key to the Vault
resource "azurerm_key_vault_secret" "insights" {
  name         = local.ai_key_name
  value        = module.app_insights.app_insights_instrumentation_key
  key_vault_id = module.keyvault.keyvault_id
}


#-------------------------------
# Log Analytics (main.tf)
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
# OSDU Identity  (security.tf)
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

// Lock the Container Registry
resource "azurerm_management_lock" "acr_lock" {
  name       = "osdu_acr_lock"
  scope      = module.container_registry.container_registry_id
  lock_level = "CanNotDelete"
}

// Lock the Diagnostics Storage Account
resource "azurerm_management_lock" "storage_lock" {
  name       = "osdu_sr_la_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}

#-------------------------------
# Output Variables  (output.tf)
#-------------------------------
output "central_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "diag_storage_account" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "diag_storage_account_id" {
  description = "The name of the storage account."
  value       = module.storage_account.id
}

output "diag_storage_containers" {
  description = "Map of storage account containers."
  value       = module.storage_account.containers
}

output "container_registry_id" {
  description = "The resource identifier of the container registry."
  value       = module.container_registry.container_registry_id
}

output "container_registry_name" {
  description = "The name of the container registry."
  value       = module.container_registry.container_registry_name
}

output "keyvault_id" {
  description = "The resource id for Key Vault"
  value       = module.keyvault.keyvault_id
}

output "log_analytics_id" {
  description = "The resource id for Log Analytics"
  value       = module.log_analytics.id
}