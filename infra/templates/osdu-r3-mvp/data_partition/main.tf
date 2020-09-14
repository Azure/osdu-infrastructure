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

provider "external" {
  version = "~> 1.0"
}

provider "null" {
  version = "~>2.1.0"
}


#-------------------------------
# Application Variables  (variables.tf)
#-------------------------------
variable "prefix" {
  description = "The workspace prefix defining the project area for this terraform deployment."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 4
}

variable "remote_state_account" {
  description = "Remote Terraform State Azure storage account name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "remote_state_container" {
  description = "Remote Terraform State Azure storage container name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "central_resources_workspace_name" {
  description = "(Required) The workspace name for the central_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

variable "resource_group_location" {
  description = "The Azure region where data storage resources in this template should be created."
  type        = string
}

variable "data_partition_name" {
  description = "The OSDU data Partition Name."
  type        = string
  default     = "opendes"
}

variable "storage_containers" {
  description = "The list of storage container names to create. Names must be unique per storage account."
  type        = list(string)
}

variable "cosmosdb_replica_location" {
  description = "The name of the Azure region to host replicated data. i.e. 'East US' 'East US 2'. More locations can be found at https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  type        = string
}

variable "cosmosdb_consistency_level" {
  description = "The level of consistency backed by SLAs for Cosmos database. Developers can chose from five well-defined consistency levels on the consistency spectrum."
  type        = string
  default     = "Session"
}

variable "cosmosdb_automatic_failover" {
  description = "Determines if automatic failover is enabled for CosmosDB."
  type        = bool
  default     = true
}

variable "cosmos_databases" {
  description = "The list of Cosmos DB SQL Databases."
  type = list(object({
    name       = string
    throughput = number
  }))
  default = []
}

variable "cosmos_sql_collections" {
  description = "The list of cosmos collection names to create. Names must be unique per cosmos instance."
  type = list(object({
    name               = string
    database_name      = string
    partition_key_path = string
    throughput         = number
  }))
  default = []
}

variable "sb_sku" {
  description = "The SKU of the namespace. The options are: `Basic`, `Standard`, `Premium`."
  type        = string
  default     = "Standard"
}

variable "sb_topics" {
  type = list(object({
    name                = string
    enable_partitioning = bool
    subscriptions = list(object({
      name               = string
      max_delivery_count = number
      lock_duration      = string
      forward_to         = string
    }))
  }))
  default = [
    {
      name                = "topic_test"
      enable_partitioning = true
      subscriptions = [
        {
          name               = "sub_test"
          max_delivery_count = 1
          lock_duration      = "PT5M"
          forward_to         = ""
        }
      ]
    }
  ]
}


#-------------------------------
# Private Variables  (common.tf)
#-------------------------------
locals {
  // sanitize names
  prefix    = replace(trimspace(lower(var.prefix)), "_", "-")
  workspace = replace(trimspace(lower(terraform.workspace)), "-", "")
  suffix    = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""
  partition = split("-", trimspace(lower(terraform.workspace)))[0]

  // base prefix for resources, prefix constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  resource_group_name  = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  storage_name         = "${replace(local.base_name_21, "-", "")}sa"
  storage_account_name = format("%s-storage", var.data_partition_name)
  storage_key_name     = format("%s-key", local.storage_account_name)

  cosmosdb_name      = "${local.base_name}-db"
  cosmos_connection  = format("%s-cosmos-connection", var.data_partition_name)
  cosmos_endpoint    = format("%s-cosmos-endpoint", var.data_partition_name)
  cosmos_primary_key = format("%s-cosmos-primary-key", var.data_partition_name)

  sb_namespace      = "${local.base_name_21}-bus"
  sb_namespace_name = format("%s-sb-namespace", var.data_partition_name)
  sb_connection     = format("%s-sb-connection", var.data_partition_name)

  eventgrid_name            = "${local.base_name_21}-grid"
  eventgrid_domain_name     = format("%s-eventgrid", var.data_partition_name)
  eventgrid_domian_key_name = format("%s-key", local.eventgrid_domain_name)
}


#-------------------------------
# Common Resources  (common.tf)
#-------------------------------
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "terraform_remote_state" "central_resources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.central_resources_workspace_name)
  }
}

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

  tags = var.resource_tags

  lifecycle {
    ignore_changes = [tags]
  }
}


#-------------------------------
# Storage
#-------------------------------
module "storage_account" {
  source = "../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = var.storage_containers
  kind                = "StorageV2"
  replication_type    = "GRS"

  resource_tags = var.resource_tags
}



// Add the Storage Account Name to the Vault
resource "azurerm_key_vault_secret" "storage_name" {
  name         = local.storage_account_name
  value        = module.storage_account.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the Storage Key to the Vault
resource "azurerm_key_vault_secret" "storage_key" {
  name         = local.storage_key_name
  value        = module.storage_account.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

#-------------------------------
# CosmosDB
#-------------------------------
module "cosmosdb_account" {
  source = "../../../modules/providers/azure/cosmosdb"

  name                     = local.cosmosdb_name
  resource_group_name      = azurerm_resource_group.main.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = var.cosmosdb_consistency_level
  databases                = var.cosmos_databases
  sql_collections          = var.cosmos_sql_collections

  resource_tags = var.resource_tags
}



// Add the CosmosDB Connection to the Vault
resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = local.cosmos_connection
  value        = module.cosmosdb_account.properties.cosmosdb.connection_strings[0]
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the CosmosDB Endpoint to the Vault
resource "azurerm_key_vault_secret" "cosmos_endpoint" {
  name         = local.cosmos_endpoint
  value        = module.cosmosdb_account.properties.cosmosdb.endpoint
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the CosmosDB Key to the Vault
resource "azurerm_key_vault_secret" "cosmos_key" {
  name         = local.cosmos_primary_key
  value        = module.cosmosdb_account.properties.cosmosdb.primary_master_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Hook up Diagnostics
resource "azurerm_monitor_diagnostic_setting" "db_diagnostics" {
  name                       = "db_diagnostics"
  target_resource_id         = module.cosmosdb_account.account_id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id

  log {
    category = "CassandraRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "ControlPlaneRequests"

    retention_policy {
      days    = 100
      enabled = true
    }
  }

  log {
    category = "DataPlaneRequests"
    enabled  = true

    retention_policy {
      days    = 100
      enabled = true
    }
  }

  log {
    category = "GremlinRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "MongoRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "PartitionKeyRUConsumption"

    retention_policy {
      days    = 100
      enabled = true
    }
  }

  log {
    category = "PartitionKeyStatistics"

    retention_policy {
      days    = 100
      enabled = true
    }
  }

  log {
    category = "QueryRuntimeStatistics"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "Requests"

    retention_policy {
      enabled = true
    }
  }
}

#-------------------------------
# Azure Service Bus (main.tf)
#-------------------------------
module "service_bus" {
  source = "../../../modules/providers/azure/service-bus2"

  name                = local.sb_namespace
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.sb_sku
  topics              = var.sb_topics

  resource_tags = var.resource_tags
}

// Add the ServiceBus Connection to the Vault
resource "azurerm_key_vault_secret" "sb_namespace" {
  name         = local.sb_namespace_name
  value        = module.service_bus.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the ServiceBus Connection to the Vault
resource "azurerm_key_vault_secret" "sb_connection" {
  name         = local.sb_connection
  value        = module.service_bus.default_connection_string
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Hook up Diagnostics
resource "azurerm_monitor_diagnostic_setting" "sb_diagnostics" {
  name                       = "sb_diagnostics"
  target_resource_id         = module.service_bus.id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id

  log {
    category = "OperationalLogs"

    retention_policy {
      days    = 100
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      days    = 100
      enabled = true
    }
  }
}

#-------------------------------
# Azure Event Grid (main.tf)
#-------------------------------
module "event_grid" {
  source = "../../../modules/providers/azure/event-grid"

  name                = local.eventgrid_name
  resource_group_name = azurerm_resource_group.main.name
  topics = [
    {
      name = format("%s-recordstopic", var.data_partition_name)
    }
  ]

  resource_tags = var.resource_tags
}

// Add the Event Grid Name to the Vault
resource "azurerm_key_vault_secret" "eventgrid_name" {
  name         = local.eventgrid_domain_name
  value        = module.event_grid.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the Event Grid Key to the Vault
resource "azurerm_key_vault_secret" "eventgrid_key" {
  name         = local.eventgrid_domian_key_name
  value        = module.event_grid.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Hook up Diagnostics
resource "azurerm_monitor_diagnostic_setting" "eg_diagnostics" {
  name                       = "eg_diagnostics"
  target_resource_id         = module.event_grid.id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id

  log {
    category = "DeliveryFailures"

    retention_policy {
      enabled = true
    }
  }

  log {
    category = "PublishFailures"

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
# Locks
#-------------------------------
resource "azurerm_management_lock" "sa_lock" {
  name       = "osdu_ds_sa_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}

resource "azurerm_management_lock" "db_lock" {
  name       = "osdu_ds_db_lock"
  scope      = module.cosmosdb_account.properties.cosmosdb.id
  lock_level = "CanNotDelete"
}

#-------------------------------
# Output Variables  (output.tf)
#-------------------------------
output "data_partition_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "data_partition_group_id" {
  description = "The resource id for the provisioned resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "The resource id of the storage account instance"
  value       = module.storage_account.id
}

output "storage_containers" {
  description = "Map of storage account containers."
  value       = module.storage_account.containers
}

output "cosmosdb_account_name" {
  description = "The name of the CosmosDB account."
  value       = module.cosmosdb_account.account_name
}

output "cosmosdb_properties" {
  description = "Properties of the deployed CosmosDB account."
  value       = module.cosmosdb_account.properties
}
