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
// This template includes locks and won't fully delete if locks aren't removed first.
// Lock: Storage
// Lock: CosmosDb
// *** WARNING  ****

// *** WARNING  ****
// This template makes changes into the Central Resources and the locks in Central have to be removed to delete.
// Lock: Key Vault
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
# Private Variables
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

  resource_group_name = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  retention_policy    = var.log_retention_days == 0 ? false : true

  storage_name            = "${replace(local.base_name_21, "-", "")}data"
  sdms_storage_name       = "${replace(local.base_name_21, "-", "")}sdms"
  cosmosdb_name           = "${local.base_name}-db"
  sb_namespace            = "${local.base_name_21}-bus"
  eventgrid_name          = "${local.base_name_21}-grid"
  eventgrid_records_topic = format("%s-recordstopic", local.eventgrid_name)

  role = "Contributor"
  rbac_principals = [
    data.terraform_remote_state.central_resources.outputs.osdu_identity_principal_id,
    data.terraform_remote_state.central_resources.outputs.principal_objectId
  ]
}



#-------------------------------
# Common Resources
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
  lifecycle { ignore_changes = [tags] }
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

// Add Access Control to Principal
resource "azurerm_role_assignment" "storage_access" {
  count = length(local.rbac_principals)

  role_definition_name = local.role
  principal_id         = local.rbac_principals[count.index]
  scope                = module.storage_account.id
}

module "sdms_storage_account" {
  source = "../../../modules/providers/azure/storage-account"

  name                = local.sdms_storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = []
  kind                = "StorageV2"
  replication_type    = "GRS"

  resource_tags = var.resource_tags
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "sdms_storage_access" {
  count = length(local.rbac_principals)

  role_definition_name = local.role
  principal_id         = local.rbac_principals[count.index]
  scope                = module.sdms_storage_account.id
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

// Add Access Control to Principal
resource "azurerm_role_assignment" "cosmos_access" {
  count = length(local.rbac_principals)

  role_definition_name = local.role
  principal_id         = local.rbac_principals[count.index]
  scope                = module.cosmosdb_account.account_id
}



#-------------------------------
# Azure Service Bus
#-------------------------------
module "service_bus" {
  source = "../../../modules/providers/azure/service-bus2"

  name                = local.sb_namespace
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.sb_sku
  topics              = var.sb_topics

  resource_tags = var.resource_tags
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "sb_access" {
  count = length(local.rbac_principals)

  role_definition_name = local.role
  principal_id         = local.rbac_principals[count.index]
  scope                = module.service_bus.id
}


#-------------------------------
# Azure Event Grid
#-------------------------------
module "event_grid" {
  source = "../../../modules/providers/azure/event-grid"

  name                = local.eventgrid_name
  resource_group_name = azurerm_resource_group.main.name

  topics = [
    {
      name = local.eventgrid_records_topic
    }
  ]

  resource_tags = var.resource_tags
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "eventgrid_access" {
  count = length(local.rbac_principals)

  role_definition_name = local.role
  principal_id         = local.rbac_principals[count.index]
  scope                = module.event_grid.id
}



#-------------------------------
# Locks
#-------------------------------
resource "azurerm_management_lock" "sa_lock" {
  name       = "osdu_ds_sa_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}

resource "azurerm_management_lock" "sdms_sa_lock" {
  name       = "osdu_sdms_sa_lock"
  scope      = module.sdms_storage_account.id
  lock_level = "CanNotDelete"
}

resource "azurerm_management_lock" "db_lock" {
  name       = "osdu_ds_db_lock"
  scope      = module.cosmosdb_account.properties.cosmosdb.id
  lock_level = "CanNotDelete"
}
