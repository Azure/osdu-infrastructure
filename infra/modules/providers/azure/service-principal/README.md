# Module service-principal

Module for managing a service principal for Azure Active Directory with the following characteristics:

- Create a Principal and Assign to a role.
- Use an existing Principal and Assign to a role.

> __This module requires the Terraform Principal to have Azure Active Directory Graph - `Application.ReadWrite.OwnedBy` Permissions if creating a principal.__


## Usage

__Sample 1:__ Create a Service Principal

_terraform_
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


__Sample 2:__ Bring your own Service Principal

_cli commands_
```bash
UNIQUE=$(echo $((RANDOM%999+100)))
NAME="iac-osdu-$UNIQUE-ad-app-management"

# Create a Service Principal
SECRET=$(az ad sp create-for-rbac --name $NAME --skip-assignment --query password -otsv)

# Retrieve the Principal Metadata Information
az ad sp list --display-name $NAME --query [].'{objectId:objectId, appId:appId, name:displayName}' -ojson

# Result
[
  {
    "appId": "2357b068-2541-4244-8866-27e23aa0a112",
    "name": "iac-osdu-246-ad-app-management",
    "objectId": "1586d1ed-dd0b-45ce-a698-f155a7becc8b"
  }
]

# Retrieve the AD Application Metadata Information
az ad app list --display-name $NAME --query [].'{object_id:objectId, name:displayName, appId:appId}' -ojson

# Result
[
  {
    "appId": "2357b068-2541-4244-8866-27e23aa0a112",
    "name": "iac-osdu-246-ad-app-management",
    "object_id": "32f1438a-6b3a-47d8-9c71-bf7fc8efbdfd"
  }
]


# Assign any API Permissions Desired
# Microsoft Graph -- Application Permissions -- Directory.Read.All  ** GRANT ADMIN-CONSENT
adObjectId=$(az ad app list --display-name $NAME --query [].objectId -otsv)
graphId=$(az ad sp list --query "[?appDisplayName=='Microsoft Graph'].appId | [0]" --all -otsv)
directoryReadAll=$(az ad sp show --id $graphId --query "appRoles[?value=='Directory.Read.All'].id | [0]" -otsv)=Role

az ad app permission add --id $adObjectId --api $graphId --api-permissions $directoryReadAll

# Grant Admin Consent
# ** REQUIRES ADMIN AD ACCESS **
az ad app permission admin-consent --id $appId 
```

_terraform_
```hcl
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

  name     = "iac-osdu-246-ad-app-management"
  
  scopes   = [azurerm_resource_group.main.id]
  role     = "Contributor"

  create_for_rbac = false
  object_id = "1586d1ed-dd0b-45ce-a698-f155a7becc8b"
  
  principal = {
    name = "iac-osdu-246-ad-app-management"
    appId = "2357b068-2541-4244-8866-27e23aa0a112"
    password = "******************************"
  }
}
```

### Input Variables

Please refer to [variables.tf](./variables.tf).

### Output Variables

Please refer to [output.tf](./output.tf).


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