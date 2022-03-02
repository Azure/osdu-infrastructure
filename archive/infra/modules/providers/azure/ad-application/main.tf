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

data "azuread_service_principal" "main" {
  count        = length(local.api_names)
  display_name = local.api_names[count.index]
}

resource "azuread_application" "main" {
  name                       = var.name
  homepage                   = coalesce(var.homepage, local.homepage)
  identifier_uris            = local.identifier_uris
  reply_urls                 = var.reply_urls
  available_to_other_tenants = var.available_to_other_tenants
  public_client              = local.public_client
  oauth2_allow_implicit_flow = var.oauth2_allow_implicit_flow
  group_membership_claims    = var.group_membership_claims
  type                       = local.type

  dynamic "required_resource_access" {
    for_each = local.required_resource_access

    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access

        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  dynamic "app_role" {
    for_each = local.app_roles

    content {
      allowed_member_types = app_role.value.member_types
      display_name         = app_role.value.name
      description          = app_role.value.description
      value                = coalesce(app_role.value.value, app_role.value.name)
      is_enabled           = app_role.value.enabled
    }
  }
}

resource "random_password" "main" {
  count   = var.password == "" ? 1 : 0
  length  = 32
  special = false
}

resource "azuread_application_password" "main" {
  count                 = var.password != null ? 1 : 0
  application_object_id = azuread_application.main.id

  value             = coalesce(var.password, random_password.main[0].result)
  end_date          = local.end_date
  end_date_relative = local.end_date_relative

  lifecycle {
    ignore_changes = all
  }
}
