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

resource "random_id" "entitlement_key" {
  byte_length = 18
}

resource "azurerm_key_vault" "keyvault" {
  name                = local.kv_name
  location            = var.resource_group_location
  soft_delete_enabled = true
  tenant_id           = data.azurerm_client_config.current.tenant_id
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku_name            = "standard"
}

module "deployment_service_principal_keyvault_access_policies" {
  source                  = "../../../../modules/providers/azure/keyvault-policy"
  vault_id                = azurerm_key_vault.keyvault.id
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_ids              = [data.azurerm_client_config.current.object_id]
  key_permissions         = ["create", "delete", "get"]
  secret_permissions      = ["set", "delete", "get", "list"]
  certificate_permissions = ["create", "delete", "get", "list", "import"]
}

/* module "aks_keyvault_ssl_cert_import" {
  source                         = "../../../../modules/providers/azure/keyvault-cert"
  key_vault_cert_import_filepath = var.ssl_certificate_file
  keyvault_id                    = azurerm_key_vault.keyvault.id
  key_vault_cert_name            = "appgw-ssl-cert"
} */

module "aks_msi_keyvault_access_policy" {
  source    = "../../../../modules/providers/azure/keyvault-policy"
  vault_id  = azurerm_key_vault.keyvault.id
  tenant_id = local.tenant_id
  object_ids = [
    module.app_management_service_principal.service_principal_object_id
  ]
  key_permissions         = ["get", "list"]
  secret_permissions      = ["get", "list"]
  certificate_permissions = ["get", "list", "import"]
}

locals {
  secrets_map = {
    # AAD Application Secrets
    aad-client-id = module.ad_application.azuread_app_ids[0]
    # Cosmos Cluster Secrets
    cosmos-endpoint    = data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.endpoint
    cosmos-primary-key = data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.primary_master_key
    cosmos-connection  = data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.connection_strings[0]
    # Service Principal Secrets
    app-dev-sp-username  = module.app_management_service_principal.service_principal_application_id
    app-dev-sp-password  = module.app_management_service_principal.service_principal_password
    app-dev-sp-tenant-id = data.azurerm_client_config.current.tenant_id
    # App Gateway AAD Pod Identity Secrets
    aks-app-gw-msi-client-id   = module.aks-gitops.kubelet_client_id
    aks-app-gw-msi-resource-id = module.aks-gitops.kubelet_resource_id
  }

  output_secret_map = {
    for secret in module.keyvault_secrets.keyvault_secret_attributes :
    secret.name => secret.id
  }
}

module "keyvault_secrets" {
  source      = "../../../../modules/providers/azure/keyvault-secret"
  keyvault_id = azurerm_key_vault.keyvault.id
  secrets     = local.secrets_map
}
