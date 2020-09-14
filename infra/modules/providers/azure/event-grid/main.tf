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

  topics = [
    for topic in var.topics : merge({
      name = ""

    }, topic)
  ]

}

## define resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_eventgrid_domain" "main" {
  name = var.name

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  tags = var.resource_tags
}

resource "azurerm_eventgrid_topic" "main" {
  count = length(local.topics)

  name                = local.topics[count.index].name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  tags = var.resource_tags
}

