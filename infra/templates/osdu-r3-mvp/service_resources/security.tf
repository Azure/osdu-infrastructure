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


/*
.Synopsis
   Terraform Security Control
.DESCRIPTION
   This file holds security settings.
*/


#-------------------------------
# Private Variables
#-------------------------------
locals {
  role = "Contributor"

  storage_account_name    = "airflow-storage"
  storage_key_name        = "${local.storage_account_name}-key"
  storage_connection_name = "${local.storage_account_name}-connection"

  postgres_password_name = "postgres-password"
  postgres_password      = coalesce(var.postgres_password, random_password.postgres[0].result)

  redis_password_name = "redis-password"
}


#-------------------------------
# Storage
#-------------------------------

// Add the Storage Account Name to the Vault
resource "azurerm_key_vault_secret" "storage_name" {
  name         = local.storage_account_name
  value        = module.storage_account.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the Storage Key to the Vault
resource "azurerm_key_vault_secret" "storage_key" {
  name         = local.storage_key_name
  value        = module.storage_account.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the Storage Connection String to the Vault
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = local.storage_connection_name
  value        = format("DefaultEndpointsProtocol=https;AccountName=%s;AccountKey=%s;EndpointSuffix=core.windows.net", local.storage_account_name, module.storage_account.primary_access_key)
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "storage_access" {
  role_definition_name = local.role
  principal_id         = data.terraform_remote_state.central_resources.outputs.principal_objectId
  scope                = module.storage_account.id
}


#-------------------------------
# PostgreSQL
#-------------------------------

// Add the Postgres Password to the Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = local.postgres_password_name
  value        = local.postgres_password
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "postgres_access" {
  role_definition_name = local.role
  principal_id         = data.terraform_remote_state.central_resources.outputs.principal_objectId
  scope                = module.postgreSQL.server_id
}


#-------------------------------
# Azure Redis Cache
#-------------------------------

// Add the Redis Password to the Vault
resource "azurerm_key_vault_secret" "redis_password" {
  name         = local.redis_password_name
  value        = module.redis_cache.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "redis_cache" {
  role_definition_name = local.role
  principal_id         = data.terraform_remote_state.central_resources.outputs.principal_objectId
  scope                = module.redis_cache.id
}


#-------------------------------
# Network
#-------------------------------

// Create a Default SSL Certificate.
resource "azurerm_key_vault_certificate" "default" {
  count = var.ssl_certificate_file == "" ? 1 : 0

  name         = local.ssl_cert_name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id

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
        dns_names = [var.dns_name, "${local.base_name}-gw.${azurerm_resource_group.main.location}.cloudapp.azure.com"]
      }

      subject            = "CN=*.contoso.com"
      validity_in_months = 12
    }
  }
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "network" {
  role_definition_name = local.role
  principal_id         = data.terraform_remote_state.central_resources.outputs.principal_objectId
  scope                = module.network.id
}


// Add Access Control to Principal
resource "azurerm_role_assignment" "app_gateway" {
  role_definition_name = local.role
  principal_id         = data.terraform_remote_state.central_resources.outputs.principal_objectId
  scope                = module.appgateway.id
}


#-------------------------------
# Airflow (main.tf)
#-------------------------------

resource "random_password" "airflow_admin_password" {
  count = var.airflow_admin_password == "" ? 1 : 0

  length           = 8
  special          = true
  override_special = "_%@"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_string" "airflow_fernete_key_rnd" {
  keepers = {
    postgresql_name = local.postgresql_name
  }
  length      = 32
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "airflow_fernet_key_secret" {
  name         = "airflow-fernet-key"
  value        = base64encode(random_string.airflow_fernete_key_rnd.result)
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

resource "azurerm_key_vault_secret" "airflow_admin_password" {
  name         = "airflow-admin-password"
  value        = local.airflow_admin_password
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}