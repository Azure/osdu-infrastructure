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

locals {
  rbac_contributor_scopes = concat(
    # Keyvault
    [module.keyvault.keyvault_id],

    # The cosmosdb resource id
    [data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.id],

    # The storage resource id
    [data.terraform_remote_state.data_sources.outputs.storage_account_id],

    # The redis resource id
    [data.terraform_remote_state.data_sources.outputs.redis_resource_id],

    # The Container Registry Id
    [data.terraform_remote_state.image_repository.outputs.container_registry_id]
  )

  app_dev_principals = [
    module.app_management_service_principal.service_principal_object_id
  ]
}

data "azurerm_virtual_network" "aks_vnet" {
  name                = module.vnet.vnet_name
  resource_group_name = azurerm_resource_group.aks_rg.name
}

module "app_management_service_principal" {
  source          = "../../../../modules/providers/azure/service-principal"
  create_for_rbac = true
  display_name    = local.ad_app_management_name
  role_name       = "Contributor"
  role_scopes     = local.rbac_contributor_scopes
}

module "ad_application" {
  source               = "../../../../modules/providers/azure/ad-application"
  resource_access_type = "Scope"
  ad_app_config = [
    {
      app_name   = local.ad_app_name
      reply_urls = []
    }
  ]
  resource_app_id  = local.graph_id
  resource_role_id = local.graph_role_id
}

resource "azurerm_role_assignment" "aks_vnet" {
  count                = length(local.app_dev_principals)
  role_definition_name = "Network Contributor"
  principal_id         = local.app_dev_principals[count.index]
  scope                = data.azurerm_virtual_network.aks_vnet.id
}

resource "azurerm_role_assignment" "aks_group" {
  count                = length(local.app_dev_principals)
  role_definition_name = "Contributor"
  principal_id         = local.app_dev_principals[count.index]
  scope                = azurerm_resource_group.aks_rg.id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = length(local.app_dev_principals)
  role_definition_name = "AcrPull"
  principal_id         = local.app_dev_principals[count.index]
  scope                = data.terraform_remote_state.image_repository.outputs.container_registry_id
}

resource "azurerm_role_assignment" "storage_roles" {
  count                = length(local.app_dev_principals)
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.app_dev_principals[count.index]
  scope                = data.terraform_remote_state.data_sources.outputs.storage_account_id
}

resource "azurerm_role_assignment" "app_gw_identity_appgw_contrib" {
  role_definition_name = "Contributor"
  principal_id         = module.app_gateway.managed_identity_principal_id
  scope                = module.app_gateway.appgateway_id
}

resource "azurerm_role_assignment" "app_gw_identity_appgw_rg_reader" {
  role_definition_name = "Reader"
  principal_id         = module.app_gateway.managed_identity_principal_id
  scope                = azurerm_resource_group.aks_rg.id
}

resource "azurerm_role_assignment" "app_gw_msi_operator" {
  role_definition_name = "Managed Identity Operator"
  principal_id         = module.app_management_service_principal.service_principal_object_id
  scope                = module.app_gateway.managed_identity_resource_id
}