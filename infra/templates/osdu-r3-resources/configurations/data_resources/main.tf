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
   This file holds the main control and resoures for bootstraping an OSDU Azure Devops Project.
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
  version = "~> 2.18.0"
  features {}
}

provider "null" {
  version = "~> 2.1.0"
}

provider "azuread" {
  version = "~> 0.7.0"
}

provider "external" {
  version = "~> 1.0"
}

provider "random" {
  version = "~> 2.3"
}

// Hook-up kubectl Provider for Terraform
provider "kubernetes" {
  version                = "~> 1.11.3"
  load_config_file       = false
  host                   = data.terraform_remote_state.service_resources.outputs.aks_kube_config.0.host
  username               = data.terraform_remote_state.service_resources.outputs.aks_kube_config.0.username
  password               = data.terraform_remote_state.service_resources.outputs.aks_kube_config.0.password
  client_certificate     = base64decode(data.terraform_remote_state.service_resources.outputs.aks_kube_config.0.client_certificate)
  client_key             = base64decode(data.terraform_remote_state.service_resources.outputs.aks_kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.service_resources.outputs.aks_kube_config.0.cluster_ca_certificate)
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

variable "resource_group_location" {
  description = "The Azure region where data storage resources in this template should be created."
  type        = string
}

variable "storage_containers" {
  description = "The list of storage container names to create. Names must be unique per storage account."
  type        = list(string)
}

variable "cosmos_db_name" {
  description = "(Required) The name that CosmosDB will be created with."
  type        = string
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
  type        = string
  default     = "Standard"
  description = "The SKU of the namespace. The options are: `Basic`, `Standard`, `Premium`."
}

variable "common_resources_workspace_name" {
  description = "(Required) The workspace name for the common_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "service_resources_workspace_name" {
  description = "(Required) The workspace name for the service_resources terraform environment / template to reference for this template."
  type        = string
}

variable "remote_state_account" {
  description = "Remote Terraform State Azure storage account name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "remote_state_container" {
  description = "Remote Terraform State Azure storage container name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "endpoint for elasticsearch cluster"
}

variable "elasticsearch_username" {
  type        = string
  description = "username for elasticsearch cluster"
}

variable "sb_topics" {
  type = list(object({
    name                         = string
    default_message_ttl          = string //ISO 8601 format
    enable_partitioning          = bool
    requires_duplicate_detection = bool
    support_ordering             = bool
    authorization_rules = list(object({
      policy_name = string
      claims      = object({ listen = bool, manage = bool, send = bool })

    }))
    subscriptions = list(object({
      name                                 = string
      max_delivery_count                   = number
      lock_duration                        = string //ISO 8601 format
      forward_to                           = string //set with the topic name that will be used for forwarding. Otherwise, set to ""
      dead_lettering_on_message_expiration = bool
      filter_type                          = string // SqlFilter is the only supported type now.
      sql_filter                           = string //Required when filter_type is set to SqlFilter
      action                               = string
    }))
  }))
  default = [
    {
      name                         = "storage_topic"
      default_message_ttl          = "PT30M" //ISO 8601 format
      enable_partitioning          = true
      requires_duplicate_detection = true
      support_ordering             = true
      authorization_rules = [
        {
          policy_name = "storage_policy"
          claims = {
            listen = true
            send   = false
            manage = false
          }
        }
      ]
      subscriptions = [
        {
          name                                 = "storage_sub_1"
          max_delivery_count                   = 1
          lock_duration                        = "PT5M" //ISO 8601 format
          forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
          dead_lettering_on_message_expiration = true
          filter_type                          = "SqlFilter"     // SqlFilter is the only supported type now.
          sql_filter                           = "color = 'red'" //Required when filter_type is set to SqlFilter
          action                               = ""
        },
        {
          name                                 = "storage_sub_2"
          max_delivery_count                   = 1
          lock_duration                        = "PT5M" //ISO 8601 format
          forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
          dead_lettering_on_message_expiration = true
          filter_type                          = "SqlFilter"      // SqlFilter is the only supported type now.
          sql_filter                           = "color = 'blue'" //Required when filter_type is set to SqlFilter
          action                               = ""
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

  // base prefix for resources, prefix constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  resource_group_name = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  storage_name        = "${replace(local.base_name_21, "-", "")}sa"
  cosmosdb_name       = "${local.base_name}-db"
  sb_namespace        = "${local.base_name_21}-bus"

  rbac_principals = [
    data.terraform_remote_state.service_resources.outputs.aad_osdu_identity_object_id,
    data.terraform_remote_state.service_resources.outputs.app_management_service_principal_id
  ]

  rbac_contributor_scopes = concat(
    # The cosmosdb resource id
    [module.cosmosdb_account.account_id],

    # The storage resource id
    [module.storage_account.id],

    # The Container Registry Id
    [data.terraform_remote_state.common_resources.outputs.container_registry_id],
  )

  key_vault_ids = [
    data.terraform_remote_state.common_resources.outputs.keyvault_id,
    data.terraform_remote_state.service_resources.outputs.keyvault_id
  ]
}


#-------------------------------
# Common Resources  (common.tf)
#-------------------------------

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "terraform_remote_state" "service_resources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.service_resources_workspace_name)
  }
}

data "terraform_remote_state" "common_resources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.common_resources_workspace_name)
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

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_management_lock" "rg_lock" {
  name       = "osdu_ds_rg_lock"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
}


#-------------------------------
# Storage
#-------------------------------
module "storage_account" {
  source = "../../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = var.storage_containers
  kind                = "StorageV2"
  replication_type    = "GRS"
}

resource "azurerm_management_lock" "sa_lock" {
  name       = "osdu_ds_sa_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}


#-------------------------------
# CosmosDB
#-------------------------------
module "cosmosdb_account" {
  source                   = "../../../../modules/providers/azure/cosmosdb"
  name                     = local.cosmosdb_name
  resource_group_name      = azurerm_resource_group.main.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = var.cosmosdb_consistency_level
  databases                = var.cosmos_databases
  sql_collections          = var.cosmos_sql_collections
}

resource "azurerm_management_lock" "db_lock" {
  name       = "osdu_ds_db_lock"
  scope      = module.cosmosdb_account.properties.cosmosdb.id
  lock_level = "CanNotDelete"
}

#-------------------------------
# Azure Service Bus (main.tf)
#-------------------------------
module "service_bus" {
  source = "../../../../modules/providers/azure/service-bus"

  namespace_name      = local.sb_namespace
  resource_group_name = azurerm_resource_group.main.name

  sku    = var.sb_sku
  topics = var.sb_topics
}


#-------------------------------
# OSDU Identity  (security.tf)
#-------------------------------
resource "azurerm_role_assignment" "database_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.cosmosdb_account.account_id
}

resource "azurerm_role_assignment" "storage_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.storage_account.id
}

resource "azurerm_role_assignment" "service_bus_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.service_bus.namespace_id
}

#-------------------------------
# Key Vault Secrets 
#-------------------------------

resource "azurerm_key_vault_secret" "cosmos_connection" {
  count        = length(local.key_vault_ids)
  name         = "cosmos-connection"
  value        = module.cosmosdb_account.properties.cosmosdb.connection_strings[0]
  key_vault_id = local.key_vault_ids[count.index]
}

resource "azurerm_key_vault_secret" "cosmos_endpoint" {
  count        = length(local.key_vault_ids)
  name         = "cosmos-endpoint"
  value        = module.cosmosdb_account.properties.cosmosdb.endpoint
  key_vault_id = local.key_vault_ids[count.index]
}

resource "azurerm_key_vault_secret" "cosmos_primary_key" {
  count        = length(local.key_vault_ids)
  name         = "cosmos-primary-key"
  value        = module.cosmosdb_account.properties.cosmosdb.primary_master_key
  key_vault_id = local.key_vault_ids[count.index]
}

resource "azurerm_key_vault_secret" "sb_connection" {
  count        = length(local.key_vault_ids)
  name         = "sb-connection"
  value        = module.service_bus.service_bus_namespace_default_primary_key
  key_vault_id = local.key_vault_ids[count.index]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  count        = length(local.key_vault_ids)
  name         = "storage-account-key"
  value        = module.storage_account.primary_access_key
  key_vault_id = local.key_vault_ids[count.index]
}

#-------------------------------
# Output Variables  (output.tf)
#-------------------------------
output "data_resource_group_name" {
  description = "The name of the resource group containing the data specific resources"
  value       = azurerm_resource_group.main.name
}

output "storage_account" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "The name of the storage account."
  value       = module.storage_account.id
}

output "storage_account_containers" {
  description = "Map of storage account containers."
  value       = module.storage_account.containers
}

output "storage_properties" {
  description = "Properties of the deployed Storage Account."
  value       = module.storage_account.properties
}

output "cosmosdb_account_name" {
  description = "The name of the CosmosDB account."
  value       = module.cosmosdb_account.account_name
}

output "cosmosdb_account_id" {
  description = "The name of the CosmosDB account."
  value       = module.cosmosdb_account.account_id
}

output "cosmosdb_properties" {
  description = "Properties of the deployed CosmosDB account."
  value       = module.cosmosdb_account.properties
}

output "sb_namespace_name" {
  description = "The service bus namespace name."
  value       = module.service_bus.namespace_name
}

output "sb_namespace_id" {
  description = "The service bus namespace id."
  value       = module.service_bus.namespace_id
}

output "sb_namespace_default_connection_string" {
  description = "The primary connection string for the Service Bus namespace authorization rule RootManageSharedAccessKey."
  value       = module.service_bus.service_bus_namespace_default_connection_string
  sensitive   = true
}

output "sb_topics" {
  description = "All topics with the corresponding subscriptions"
  value       = module.service_bus.topics
}
