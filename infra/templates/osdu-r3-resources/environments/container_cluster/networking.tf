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

module "vnet" {
  source = "github.com/microsoft/bedrock?ref=master//cluster/azure/vnet"

  vnet_name           = local.vnet_name
  address_space       = var.address_space
  resource_group_name = azurerm_resource_group.aks_rg.name
  subnet_names        = [local.aks_subnet_name]
  subnet_prefixes     = [var.subnet_prefix_aks]

  tags = {
    environment = "container_cluster"
  }
}

resource "azurerm_subnet" "aks" {
  name                 = local.aks_subnet_name
  virtual_network_name = module.vnet.vnet_name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  address_prefix       = var.subnet_prefix_aks
}

resource "azurerm_subnet" "app_gw" {
  name                 = local.agw_subnet_name
  virtual_network_name = module.vnet.vnet_name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  address_prefix       = var.subnet_prefix_app_gw
}

module "app_gateway" {
  source                    = "../../../../modules/providers/azure/app-gateway"
  appgateway_name           = local.app_gw_name
  resource_group_name       = azurerm_resource_group.aks_rg.name
  ssl_key_vault_secret_id   = module.aks_keyvault_ssl_cert_import.secret_id
  keyvault_id               = module.keyvault.keyvault_id
  virtual_network_subnet_id = azurerm_subnet.app_gw.id
  user_identity_name        = local.app_gw_identity_name
  user_identity_rg          = module.aks-gitops.node_resource_group
}