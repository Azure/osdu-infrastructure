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

variable "name" {
  type        = string
  description = "The name of the service principal."
}

variable "password" {
  type        = string
  description = "A password for the service principal. (Optional)"
  default     = ""
}

variable "end_date" {
  type        = string
  description = "The relative duration or RFC3339 date after which the password expire."
  default     = "2Y"
}

variable "role" {
  type        = string
  description = "The name of a role for the service principal."
  default     = ""
}

variable "scopes" {
  type        = list(string)
  description = "List of scopes the role assignment applies to."
  default     = []
}

variable "create_for_rbac" {
  description = "Create a new Service Principle"
  type        = bool
  default     = true
}

variable "object_id" {
  description = "Object Id of an existing AD app to be assigned to a role."
  type        = string
  default     = ""
}

variable "principal" {
  description = "Bring your own Principal metainformation. Optional: {name, appId, password}"
  type        = map(string)
  default     = {}
}


variable "api_permissions" {
  type        = any
  default     = []
  description = "List of API permissions."
}



locals {
  create_count = var.create_for_rbac == true ? 1 : 0

  date = regexall("^(?:(\\d{4})-(\\d{2})-(\\d{2}))[Tt]?(?:(\\d{2}):(\\d{2})(?::(\\d{2}))?(?:\\.(\\d+))?)?([Zz]|[\\+|\\-]\\d{2}:\\d{2})?$", var.end_date)

  duration = regexall("^(?:(\\d+)Y)?(?:(\\d+)M)?(?:(\\d+)W)?(?:(\\d+)D)?(?:(\\d+)h)?(?:(\\d+)m)?(?:(\\d+)s)?$", var.end_date)

  service_principals = {
    for s in data.azuread_service_principal.main : s.display_name => {
      application_id     = s.application_id
      display_name       = s.display_name
      app_roles          = { for p in s.app_roles : p.value => p.id }
      oauth2_permissions = { for p in s.oauth2_permissions : p.value => p.id }
    }
  }

  api_permissions = [
    for p in var.api_permissions : merge({
      id                 = ""
      name               = ""
      app_roles          = []
      oauth2_permissions = []
    }, p)
  ]

  api_names = local.api_permissions[*].name

  required_resource_access = [
    for a in local.api_permissions : {
      resource_app_id = local.service_principals[a.name].application_id
      resource_access = concat(
        [for p in a.app_roles : {
          id   = local.service_principals[a.name].app_roles[p]
          type = "Role"
        }]
      )
    }
  ]

  end_date_relative = length(local.duration) > 0 ? format(
    "%dh",
    (
      (coalesce(local.duration[0][0], 0) * 24 * 365) +
      (coalesce(local.duration[0][1], 0) * 24 * 30) +
      (coalesce(local.duration[0][2], 0) * 24 * 7) +
      (coalesce(local.duration[0][3], 0) * 24) +
      coalesce(local.duration[0][4], 0)
    )
  ) : null

  end_date = length(local.date) > 0 ? format(
    "%02d-%02d-%02dT%02d:%02d:%02d.%02d%s",
    local.date[0][0],
    local.date[0][1],
    local.date[0][2],
    coalesce(local.date[0][3], "23"),
    coalesce(local.date[0][4], "59"),
    coalesce(local.date[0][5], "00"),
    coalesce(local.date[0][6], "00"),
    coalesce(local.date[0][7], "Z")
  ) : null
}
