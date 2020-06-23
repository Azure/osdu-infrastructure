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

module "service_principal" {
  source = "../"

  name     = format("${local.name}-%s-ad-app-management", random_id.main.hex)
  role     = "Contributor"
  scopes   = [azurerm_resource_group.main.id]
  end_date = "1W"

  api_permissions = [
    {
      name = "Microsoft Graph"
      app_roles = [
        "Directory.Read.All"
      ]
    }
  ]

}
