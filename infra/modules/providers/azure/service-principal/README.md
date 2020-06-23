# Module service-principal

Module for managing a service principal for Azure Active Directory with the following characteristics:

- Create a Principal and Assign to a role or use an existing principal.

> __This module requires the Terraform Principal to have Azure Active Directory Graph - `Application.ReadWrite.OwnedBy` Permissions.__


## Usage

```
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
  source = "https://github.com/azure/osdu-infrastructure/infra/modules/providers/azure/service-principal"

  name = format("${local.name}-%s-ad-app-management", random_id.main.hex)

  role   = "Contributor"
  scopes = [azurerm_resource_group.main.id]

  api_permissions = [
    {
      name = "Microsoft Graph"
      oauth2_permissions = [
        "User.Read.All",
        "Directory.Read.All"
      ]
    }
  ]

  end_date = "1W"
}
```

## Inputs

| Variable Name | Type       | Description                          | 
| ------------- | ---------- | ------------------------------------ |
| `name`        | _string_   | The name of the service principal.     |
| `password`    | _string_   | A password for the service principal. (Optional).  |
| `end_date`    | _string_   | The relative duration or RFC3339 date after which the password expire.|
| `role`        | _string_   | The name of a role for the service principal. |
| `scopes`      | _list_     | List of scopes the role assignment applies to. |
| `object_id`   | string     | Object Id of an existing service principle to be assigned to a role. |


## Outputs

Once the deployments are completed successfully, the output for the current module will be in the format mentioned below:

- `name`: The Service Principal Display Name.
- `object_id`: The Service Principal Object Id.
- `tenant_id`: The Service Principal Tenant Id.
- `client_id`: The Service Principal Client Id (Application Id)
- `client_secret`: The Service Principal Client Secret (Application Password).


## License
Copyright © Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.