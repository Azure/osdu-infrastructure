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
  version = "~>1.40.0"
}

provider "null" {
  version = "~>2.1.0"
}

provider "azuread" {
  version = "~>0.7.0"
}

provider "external" {
  version = "~> 1.0"
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_string" "workspace_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name = replace(trimspace(lower(terraform.workspace)), "_", "-")
    app_id  = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = max(1, var.randomization_level) // error for zero-length
  special = false
  upper   = false
}

locals {
  // sanitize names
  app_id  = random_string.workspace_scope.keepers.app_id
  region  = replace(trimspace(lower(var.resource_group_location)), "_", "-")
  ws_name = random_string.workspace_scope.keepers.ws_name
  suffix  = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""

  // base prefix for resources, prefix constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.app_id) > 0 ? "${local.ws_name}${local.suffix}-${local.app_id}" : "${local.ws_name}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  tenant_id = data.azurerm_client_config.current.tenant_id
  /*   OpenDES app services require the entitlements_service_endpoint + legal_service_endpoint app settings
     which isn't resolved until the authn_app_service module completes, hence creating
     a circular reference. The least pervasive solution that I was able to arrive to was to determine
     the URI of the entitlement in this file.

     We could capture the entitlement and legal app service definitions(ie var.app_services) into their
     own variables, but that gets messy as we'd need to call the app-service module three times
     and concat the results in several places.
 */
  entitlement_service_postfix = "entitlements"
  entitlement_context         = "/entitlements/v1"
  legal_service_postfix       = "legal"
  legal_context               = "/api/legal/v1"
  storage_service_postfix     = "storage"
  storage_context             = "/api/storage/v2"
  indexer_service_postfix     = "indexer"
  indexer_context             = "/api/indexer/v2"
  search_service_postfix      = "search"
  // Resource names
  data_store_rg_name          = "${local.base_name_83}-ds-rg"               // resource group used for admin resources (max 90 chars)
  app_rg_name                 = "${local.base_name_83}-app-rg"              // app resource group (max 90 chars)
  data_store_rg_lock          = "${local.base_name_83}-ds-rg-delete-lock"   // management lock to prevent deletes
  app_rg_lock                 = "${local.base_name_83}-app-rg-delete-lock"  // management lock to prevent deletes
  sp_name                     = "${local.base_name}-sp"                     // service plan
  ai_name                     = "${local.base_name}-ai"                     // app insights
  kv_name                     = "${local.base_name_21}-kv"                  // key vault (max 24 chars)
  svc_princ_name              = "${local.base_name}-svc-principal"          // service principal
  ad_app_name                 = "${local.base_name}-ad-app"                 // service principal
  storage_name                = "${replace(local.base_name_21, "-", "")}sa" // storage account
  cosmosdb_name               = "${local.base_name_21}-cosmosdb"            // cosmosdb account (max 44 chars )
  ad_app_management_name      = "${local.base_name}-ad-app-management"
  app_svc_name_prefix         = local.base_name_21
  auth_svc_name_prefix        = "${local.base_name_21}-au"
  cosmos_db_name              = "dev-osdu-r2-db"
  storage_app_name            = format("%s-%s", local.auth_svc_name_prefix, lower(local.storage_service_postfix))
  legal_app_name              = format("%s-%s", local.auth_svc_name_prefix, lower(local.legal_service_postfix))
  indexer_app_name            = format("%s-%s", local.auth_svc_name_prefix, lower(local.indexer_service_postfix))
  entitlement_app_service_uri = format("https://%s-%s.azurewebsites.net%s", local.auth_svc_name_prefix, lower(local.entitlement_service_postfix), local.entitlement_context)
  legal_app_service_uri       = format("https://%s-%s.azurewebsites.net%s", local.auth_svc_name_prefix, lower(local.legal_service_postfix), local.legal_context)
  storage_app_service_uri     = format("https://%s-%s.azurewebsites.net%s", local.auth_svc_name_prefix, lower(local.storage_service_postfix), local.storage_context)
  indexer_app_service_uri     = format("https://%s-%s.azurewebsites.net%s", local.auth_svc_name_prefix, lower(local.indexer_service_postfix), local.indexerr_context)
  graph_id                    = "00000003-0000-0000-c000-000000000000"      // ID for Microsoft Graph API
  graph_role_id               = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"      // ID for User.Read API
  elastic_search_name         = "${local.base_name_21}-es"                  // elastic search deployment
  sb_namespace                = "${local.base_name_21}sb"                   // service bus namespace name (max 50 chars)
  acr_name                    = "${replace(local.base_name_21, "-", "")}cr" // Container Registry Name
  functionapp_name            = "${local.base_name_21}"                     // Function App Name Prefix
  function_storage_name       = "${replace(local.base_name_21, "-", "")}fa" // storage account
  app_service_global_config = {
    aad_client_id                 = format(local.app_setting_kv_format, local.output_secret_map.aad-client-id)
    appinsights_key               = format(local.app_setting_kv_format, local.output_secret_map.appinsights-key)
    search_service_endpoint       = format("https://%s-%s.azurewebsites.net/api/search/v2/query", local.auth_svc_name_prefix, lower(local.search_service_postfix))
    legal_service_endpoint        = local.legal_app_service_uri
    storage_service_endpoint      = local.storage_app_service_uri
    entitlements_service_api_key  = format(local.app_setting_kv_format, local.output_secret_map.entitlement-key)
    entitlements_app_key          = format(local.app_setting_kv_format, local.output_secret_map.entitlement-key)
    entitlements_service_endpoint = local.entitlement_app_service_uri
    cosmosdb_account              = format(local.app_setting_kv_format, local.output_secret_map.cosmos-endpoint)
    cosmosdb_database             = local.cosmos_db_name
    legal_service_region          = var.resource_group_location
    # TODO: remove after MI migration is complete
    cosmosdb_key = format(local.app_setting_kv_format, local.output_secret_map.cosmos-primary-key)
    # TODO: remove after MI migration is complete
    servicebus_connection_string = format(local.app_setting_kv_format, local.output_secret_map.sb-connection)
    storage_account              = module.storage_account.name
    # TODO: remove after MI migration is complete
    storage_account_key       = format(local.app_setting_kv_format, local.output_secret_map.storage-account-key)
    servicebus_namespace_name = module.service_bus.namespace_name
  }
  function_app_global_config = {
    SERVICE_BUS        = format(local.app_setting_kv_format, local.output_secret_map.sb-connection)
    SUBSCRIPTION_NAME  = [for topic in var.sb_topics : topic if topic.name == "recordstopic"][0].subscriptions[0].name
    INDEXER_WORKER_URL = format("%s/%s", local.indexer_app_service_uri, "_dps/task-handlers/index-worker")
  }
}
