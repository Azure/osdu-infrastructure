# keyvault-secret

A terraform module to provide Key Vaults secrets for existing Key Vaults in Azure with the following characteristics:

- Secrets have a name that identifies them in the URL/ID
- Secrets have a secret value that gets encrypted and protected by the key vault

## Usage

Key Vault secret usage example:

```hcl
secrets = {
    "secret-sauce" = "chunky marinara"
}

kv_id = "234222"

module "keyvault-secret" {
  source               = "../../modules/providers/azure/keyvault-secret"
  keyvault_id          = kv_id
  secrets              = secrets
}

data "key-vault-secret-output" {
  depends_on   = [keyvault-secret]
  name         = keys(local.secrets)[0]
  key_vault_id = kv_id
}
```

## Variables Reference

The following variables are used:

- `secrets`: A map of Key Vault Secrets. The Key/Value association is the KeyVault secret name and value.
- `keyvault_id`: The id of the Key Vault.

## Attributes Reference

The following attributes are exported:

- `keyvault_secret_attributes`: The properties of a Key Vault secret.


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