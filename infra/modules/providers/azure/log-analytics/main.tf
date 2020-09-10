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

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  tags = var.resource_tags
}

resource "azurerm_security_center_workspace" "main" {
  count = length(var.security_center_subscription)

  scope        = "/subscriptions/${element(var.security_center_subscription, count.index)}"
  workspace_id = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_log_analytics_solution" "main" {
  count = length(var.solutions)

  solution_name         = var.solutions[count.index].solution_name
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = var.solutions[count.index].publisher
    product   = var.solutions[count.index].product
  }
}