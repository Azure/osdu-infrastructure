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

###
# This next block of Terraform configures the Service Principal
# that will be used by the application teams to deploy service
# code, configure and manage KeyVault secrets and manage App
# Service plans, among other things.
###

locals {
  rbac_contributor_scopes = concat(
    # The app service plan -- enables management of plan, scaling rules, etc...
    [module.service_plan.app_service_plan_id],

    # The cosmosdb resource id
    [module.cosmosdb_account.properties.cosmosdb.id],

    # The storage resource id
    [module.storage_account.id],

    # The Container Registry Id
    [module.container_registry.container_registry_id],

    # App services and the associated slots -- enables management of deployments, etc...
    # Note: RBAC for slots is inherited and does not need to be configured separately
    module.authn_app_service.app_service_ids,

    # The Function App
    module.function_app.ids
  )

  storage_role_principals = [
    module.authn_app_service.app_service_identity_config_data[local.storage_app_name],
    module.authn_app_service.app_service_identity_config_data[local.legal_app_name],
    module.app_management_service_principal.id
  ]

  service_bus_role_principals = [
    module.authn_app_service.app_service_identity_config_data[local.storage_app_name],
    module.authn_app_service.app_service_identity_config_data[local.legal_app_name],
    module.authn_app_service.app_service_identity_config_data[local.indexer_app_name],
    module.app_management_service_principal.id
  ]
}

module "app_management_service_principal" {
  source          = "../../modules/providers/azure/service-principal"
  create_for_rbac = true
  name            = local.ad_app_management_name
  role            = "Contributor"
  scopes          = local.rbac_contributor_scopes

  api_permissions = [
    {
      name = "Microsoft Graph"
      app_roles = [
        "Directory.Read.All"
      ]
    }
  ]
}

resource "azurerm_role_assignment" "storage_roles" {
  count                = length(local.storage_role_principals)
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.storage_role_principals[count.index]
  scope                = module.storage_account.id
}

resource "azurerm_role_assignment" "service_bus_roles" {
  count                = length(local.service_bus_role_principals)
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = local.service_bus_role_principals[count.index]
  scope                = module.service_bus.namespace_id
}
