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
  features {}
}

locals {
  ssl_cert_name = "test-ssl"
  location      = "eastus2"
}


module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = local.location
}

module "keyvault" {
  source = "../../keyvault"

  keyvault_name       = substr("osdu-module-kv-${module.resource_group.random}", 0, 24)
  resource_group_name = module.resource_group.name
}

resource "azurerm_key_vault_certificate" "test" {
  name         = local.ssl_cert_name
  key_vault_id = module.keyvault.keyvault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "osdu-module-gw-${module.resource_group.random}.${local.location}.cloudapp.azure.com"]
      }

      subject            = "CN=*.contoso.com"
      validity_in_months = 12
    }
  }
}


module "network" {
  source = "../../network"

  name                = "osdu-module-vnet-${module.resource_group.random}"
  resource_group_name = module.resource_group.name

  address_space   = "10.10.0.0/16"
  dns_servers     = ["8.8.8.8"]
  subnet_prefixes = ["10.10.1.0/24", "10.10.2.0/24"]
  subnet_names    = ["frontend", "backend"]

  # Tags
  resource_tags = {
    osdu = "module"
  }
}

module "appgateway" {
  source = "../"

  name                 = "osdu-module-gw-${module.resource_group.random}"
  resource_group_name  = module.resource_group.name
  vnet_name            = module.network.name
  vnet_subnet_id       = module.network.subnets[1]
  keyvault_id          = module.keyvault.keyvault_id
  keyvault_secret_id   = azurerm_key_vault_certificate.test.secret_id
  ssl_certificate_name = local.ssl_cert_name

  # Tags
  resource_tags = {
    osdu = "module"
  }
}