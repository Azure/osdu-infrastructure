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
resource "azurerm_key_vault_certificate" "kv_cert_import" {
  name         = var.key_vault_cert_name
  key_vault_id = var.keyvault_id

  certificate {
    contents = filebase64(var.key_vault_cert_import_filepath)
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 4096
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = var.key_vault_content_type
    }
  }
}
