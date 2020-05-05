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

module "provider" {
  source = "../../../../modules/providers/azure/provider"
}

provider "azurerm" {
  version = "~> 2.5.0"
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_string" "workspace_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name    = replace(trimspace(lower(terraform.workspace)), "_", "-")
    cluster_id = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = max(1, var.randomization_level) // error for zero-length
  special = false
  upper   = false
}

locals {
  // sanitize names
  cluster_id = replace(trimspace(lower(var.prefix)), "_", "-")
  region     = replace(trimspace(lower(var.resource_group_location)), "_", "-")
  ws_name    = random_string.workspace_scope.keepers.ws_name
  suffix     = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""

  // base prefix for resources, prefix constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.cluster_id) > 0 ? "${local.ws_name}${local.suffix}-${local.cluster_id}" : "${local.ws_name}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  tenant_id              = data.azurerm_client_config.current.tenant_id
  aks_dns_prefix         = local.base_name_60
  kv_name                = "${local.base_name_21}-kv" // key vault (max 24 chars)
  aks_rg_name            = "${local.base_name_21}-aks-rg"
  app_gw_identity_name   = "${local.base_name_21}-app-gw-identity"
  aks_cluster_name       = "${local.base_name_21}-aks" // the concatenation of resource group and cluster name can't exceed 66 characters https://docs.microsoft.com/en-us/azure/aks/troubleshooting#what-naming-restrictions-are-enforced-for-aks-resources-and-parameters
  vnet_name              = "${local.base_name_60}-vnet"
  app_gw_name            = "${local.base_name_60}-appgw"
  aks_subnet_name        = "${local.aks_cluster_name}-aks-subnet"
  agw_subnet_name        = "${local.aks_cluster_name}-app-gw-subnet"
  ai_name                = "${local.base_name}-ai" // app insights
  ad_app_management_name = "${local.base_name}-ad-app-management"
  sb_namespace           = "${local.base_name_21}sb"              // service bus namespace name (max 50 chars)
  ad_app_name            = "${local.base_name}-ad-app"            // service principal
  graph_id               = "00000003-0000-0000-c000-000000000000" // ID for Microsoft Graph API
  graph_role_id          = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" // ID for User.Read API
}

data "terraform_remote_state" "data_sources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.data_sources_workspace_name)
  }
}

data "terraform_remote_state" "image_repository" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.image_repository_workspace_name)
  }
}
