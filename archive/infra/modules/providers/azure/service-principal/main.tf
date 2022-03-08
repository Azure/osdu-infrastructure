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

resource "random_password" "main" {
  count   = local.create_count != 0 && var.password != null ? 1 : 0
  length  = 32
  special = false
}

data "azuread_service_principal" "main" {
  count        = length(local.api_names)
  display_name = local.api_names[count.index]
}


resource "azuread_application" "main" {
  count                      = local.create_count
  name                       = var.name
  available_to_other_tenants = false

  dynamic "required_resource_access" {
    for_each = local.required_resource_access
    iterator = resource
    content {
      resource_app_id = resource.value.resource_app_id

      dynamic "resource_access" {
        for_each = resource.value.resource_access
        iterator = access
        content {
          id   = access.value.id
          type = access.value.type
        }
      }
    }
  }
}

resource "azuread_service_principal" "main" {
  count          = local.create_count
  application_id = azuread_application.main[0].application_id
}

resource "azurerm_role_assignment" "main" {
  count                = length(var.scopes)
  role_definition_name = var.role
  principal_id         = var.create_for_rbac == true ? azuread_service_principal.main[0].object_id : var.object_id
  scope                = var.scopes[count.index]
}

resource "azuread_service_principal_password" "main" {
  count                = local.create_count != 0 && var.password != null ? 1 : 0
  service_principal_id = azuread_service_principal.main[0].id

  value             = coalesce(var.password, random_password.main[0].result)
  end_date          = local.end_date
  end_date_relative = local.end_date_relative

  lifecycle {
    ignore_changes = all
  }
}
