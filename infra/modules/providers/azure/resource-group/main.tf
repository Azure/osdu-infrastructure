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

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  tags     = var.resource_tags
}

resource "random_id" "main" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.main.name
  }

  byte_length = 8
}

resource "azurerm_management_lock" "main" {
  count      = var.isLocked ? 1 : 0
  name       = "${azurerm_resource_group.main.name}-delete-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"

  lifecycle {
    prevent_destroy = true
  }
}