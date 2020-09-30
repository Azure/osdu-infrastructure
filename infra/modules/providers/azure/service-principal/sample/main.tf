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

provider "azurerm" {
  version = "=1.44.0"
  # features {}
}

provider "azuread" {
  version = "=0.7.0"
}


locals {
  name     = "iac-osdu"
  location = "southcentralus"
}

resource "random_id" "main" {
  keepers = {
    name = local.name
  }

  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  name     = format("${local.name}-%s", random_id.main.hex)
  location = local.location
}

# This Example Creates a Service Principal
# module "service_principal" {
#   source = "../"

#   name     = format("${local.name}-%s-ad-app-management", random_id.main.hex)
#   role     = "Contributor"
#   scopes   = [azurerm_resource_group.main.id]
#   end_date = "1W"

#   api_permissions = [
#     {
#       name = "Microsoft Graph"
#       app_roles = [
#         "User.Read.All",
#         "Directory.Read.All"
#       ]
#     }
#   ]
# }

# This Example Uses an Existing Service Principal
module "service_principal" {
  source = "../"

  name   = "iac-osdu-246-ad-app-management"
  scopes = [azurerm_resource_group.main.id]
  role   = "Contributor"

  create_for_rbac = false
  object_id       = "1586d1ed-dd0b-45ce-a698-f155a7becc8b"

  principal = {
    name     = "iac-osdu-246-ad-app-management"
    appId    = "2357b068-2541-4244-8866-27e23aa0a112"
    password = "******************************"
  }
}

output "id" {
  description = "The ID of the Azure AD Service Principal"
  value       = module.service_principal.id
}

output "name" {
  description = "The Display Name of the Azure AD Application associated with this Service Principal"
  value       = module.service_principal.name
}

output "client_id" {
  description = "The ID of the Azure AD Application"
  value       = module.service_principal.client_id
}

output "client_secret" {
  description = "The password of the generated service principal. This is only exported when create_for_rbac is true."
  value       = module.service_principal.client_secret
}
