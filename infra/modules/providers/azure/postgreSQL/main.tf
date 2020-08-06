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


data "azurerm_resource_group" "main" {
    name = var.resource_group_name
}

/* data "azurerm_virtual_network" "main" {
    name = var.virtual_network_name
    resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "main" {
    name = var.subnet_name
    resource_group_name = data.azurerm_resource_group.main.name
    virtual_network_name = data.azurerm_virtual_network.main.name
} */

resource "azurerm_postgresql_server" "main" {
    name = var.db_name
    location = data.azurerm_resource_group.main.location
    resource_group_name = var.resource_group_name

    public_network_access_enabled = var.public_network_access

    administrator_login = var.admin_user
    administrator_login_password = var.admin_password

    sku_name = var.sku

    storage_mb                   = var.storage_mb
    backup_retention_days        = var.backup_retention_days
    geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
    auto_grow_enabled            = var.auto_grow_enabled


    version                      = var.server_version
    ssl_enforcement_enabled      = var.ssl_enforcement_enabled
}

resource "azurerm_postgresql_database" "main" {
  name                = var.db_name
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}