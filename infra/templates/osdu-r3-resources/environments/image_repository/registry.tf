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

resource "random_string" "naming_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name = replace(trimspace(lower(terraform.workspace)), "-", "")
    prefix  = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = 4
  special = false
  upper   = false
}

locals {
  workspace               = replace(trimspace(lower(terraform.workspace)), "-", "")
  resource_group_name     = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.naming_scope.result)
  container_registry_name = format("%s%s%sacr", var.prefix, local.workspace, random_string.naming_scope.result)
}

resource "azurerm_resource_group" "container_rg" {
  name     = local.resource_group_name
  location = var.resource_group_location
}

module "container_registry" {
  source = "../../../../modules/providers/azure/container-registry"

  container_registry_name = local.container_registry_name
  resource_group_name     = azurerm_resource_group.container_rg.name

  container_registry_sku           = var.container_registry_sku
  container_registry_admin_enabled = false
}

resource "azurerm_management_lock" "acr_lock" {
  name       = "osdu_acr_lock"
  scope      = module.container_registry.container_registry_id
  lock_level = "CanNotDelete"
}