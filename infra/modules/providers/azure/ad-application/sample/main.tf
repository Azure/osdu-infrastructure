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

provider "azuread" {
  version = "=0.7.0"
}

locals {
  name = "iac-osdu"
}

resource "random_id" "main" {
  keepers = {
    name = local.name
  }

  byte_length = 8
}


module "ad-application" {
  source = "../"

  name = format("${local.name}-%s-ad-app-management", random_id.main.hex)

  group_membership_claims = "All"

  reply_urls = [
    "https://iac-osdu.com",
    "https://iac-osdu.com/.auth/login/aad/callback"
  ]

  api_permissions = [
    {
      name = "Microsoft Graph"
      oauth2_permissions = [
        "User.Read"
      ]
    }
  ]

  app_roles = [
    {
      name        = "test"
      description = "test"
      member_types = [
        "Application"
      ]
    }
  ]
}
