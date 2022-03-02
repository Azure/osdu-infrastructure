# keyvault

A terraform module to provide key vaults in Azure with the following characteristics:

- Generates or updates a target key vault resource in azure: `keyvault_name`.
- The key vault is created in a specified resource group: `resource_group_name`.
- An access policy is created in the vault based on the deployment's service principal and tenant: environment variables `ARM_TENANT_ID` `ARM_CLIENT_SECRET` `ARM_CLIENT_ID`.
- Key Vault SKU is configurable: `keyvault_sku`. Defaults to `standard`.
- Access policy permissions for the deployment's service principal are configurable: `keyvault_key_permissions`, `keyvault_secret_permissions` and `keyvault_certificate_permissions`.
- Specified resource tags are updated to the targeted vault: `resource_tags`.

## Usage

Key Vault usage example:

```hcl

module "keyvault" {
  source              = "../../modules/providers/azure/keyvault"
  keyvault_name       = "${local.kv_name}"
  resource_group_name = "${azurerm_resource_group.svcplan.name}"
}
```

## Attributes Reference

The following attributes are exported:

- `keyvault_id`: The id of the Keyvault.
- `keyvault_uri`: The uri of the keyvault.
- `keyvault_name`: The name of the Keyvault.

## Argument Reference

Supported arguments for this module are available in [variables.tf](./variables.tf). 

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