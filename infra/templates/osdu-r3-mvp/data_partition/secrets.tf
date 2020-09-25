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
   Terraform Secrets Control
.DESCRIPTION
   This file holds KV Secrets.
*/


#-------------------------------
# Private Variables
#-------------------------------
locals {
  partition_id = format("%s-id", var.data_partition_name)

  storage_account_name = format("%s-storage", var.data_partition_name)
  storage_key_name     = format("%s-key", local.storage_account_name)

  sdms_storage_account_name = format("%s-sdms-storage", var.data_partition_name)
  sdms_storage_key_name     = format("%s-key", local.sdms_storage_account_name)

  cosmos_connection  = format("%s-cosmos-connection", var.data_partition_name)
  cosmos_endpoint    = format("%s-cosmos-endpoint", var.data_partition_name)
  cosmos_primary_key = format("%s-cosmos-primary-key", var.data_partition_name)

  sb_namespace_name = format("%s-sb-namespace", var.data_partition_name)
  sb_connection     = format("%s-sb-connection", var.data_partition_name)

  eventgrid_domain_name            = format("%s-eventgrid", var.data_partition_name)
  eventgrid_domain_key_name        = format("%s-key", local.eventgrid_domain_name)
  eventgrid_records_topic_name     = format("%s-recordstopic", local.eventgrid_domain_name)
  eventgrid_records_topic_endpoint = format("https://%s.%s-1.eventgrid.azure.net/api/events", local.eventgrid_records_topic, var.resource_group_location)
}


#-------------------------------
# Partition
#-------------------------------
resource "azurerm_key_vault_secret" "partition_id" {
  name         = local.partition_id
  value        = var.data_partition_name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}



#-------------------------------
# Storage
#-------------------------------
resource "azurerm_key_vault_secret" "storage_name" {
  name         = local.storage_account_name
  value        = module.storage_account.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = local.storage_key_name
  value        = module.storage_account.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "sdms_storage_name" {
  name         = local.sdms_storage_account_name
  value        = module.sdms_storage_account.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "sdms_storage_key" {
  name         = local.sdms_storage_key_name
  value        = module.sdms_storage_account.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}



#-------------------------------
# CosmosDB
#-------------------------------
resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = local.cosmos_connection
  value        = module.cosmosdb_account.properties.cosmosdb.connection_strings[0]
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "cosmos_endpoint" {
  name         = local.cosmos_endpoint
  value        = module.cosmosdb_account.properties.cosmosdb.endpoint
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "cosmos_key" {
  name         = local.cosmos_primary_key
  value        = module.cosmosdb_account.properties.cosmosdb.primary_master_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}



#-------------------------------
# Azure Service Bus
#-------------------------------
resource "azurerm_key_vault_secret" "sb_namespace" {
  name         = local.sb_namespace_name
  value        = module.service_bus.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "sb_connection" {
  name         = local.sb_connection
  value        = module.service_bus.default_connection_string
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}



#-------------------------------
# Azure Event Grid
#-------------------------------
resource "azurerm_key_vault_secret" "eventgrid_name" {
  name         = local.eventgrid_domain_name
  value        = module.event_grid.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "eventgrid_key" {
  name         = local.eventgrid_domain_key_name
  value        = module.event_grid.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "recordstopic_name" {
  name         = local.eventgrid_records_topic_name
  value        = local.eventgrid_records_topic_endpoint
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}
