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
  name                = var.name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = var.resource_tags

  administrator_login          = var.admin_user
  administrator_login_password = var.admin_password

  sku_name                     = var.sku
  storage_mb                   = var.storage_mb
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  auto_grow_enabled            = var.auto_grow_enabled
  version                      = var.server_version
  ssl_enforcement_enabled      = var.ssl_enforcement_enabled

  public_network_access_enabled = var.public_network_access
}

resource "azurerm_postgresql_database" "main" {
  depends_on          = [azurerm_postgresql_server.main]
  count               = length(var.databases)
  name                = var.databases[count.index]
  server_name         = azurerm_postgresql_server.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  charset             = var.db_charset
  collation           = var.db_collation
}

resource "azurerm_postgresql_firewall_rule" "main" {
  count               = length(var.firewall_rules)
  name                = format("%s%s", var.firewall_rule_prefix, lookup(var.firewall_rules[count.index], "name", count.index))
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name
  start_ip_address    = var.firewall_rules[count.index]["start_ip"]
  end_ip_address      = var.firewall_rules[count.index]["end_ip"]
}

resource "azurerm_postgresql_virtual_network_rule" "main" {
  count               = length(var.vnet_rules)
  name                = format("%s%s", var.vnet_rule_name_prefix, lookup(var.vnet_rules[count.index], "name", count.index))
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name
  subnet_id           = var.vnet_rules[count.index]["subnet_id"]
}

resource "azurerm_postgresql_configuration" "main" {
  count               = length(keys(var.postgresql_configurations))
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name

  name  = element(keys(var.postgresql_configurations), count.index)
  value = element(values(var.postgresql_configurations), count.index)
}