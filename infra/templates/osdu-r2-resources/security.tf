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

    # The redis resource id
    [module.cache.id],

    # The Container Registry Id
    [module.container_registry.container_registry_id],

    # App services and the associated slots -- enables management of deployments, etc...
    # Note: RBAC for slots is inherited and does not need to be configured separately
    module.authn_app_service.app_service_ids,

    # TODO: Add KeyVault service ID here
    #   https://dev.azure.com/slb-des-ext-collaboration/open-data-ecosystem/_boards/board/t/microsoft-open-data-ecosystem/Stories/?workitem=752
    # TODO: Add AzureFunctions service ID here
    #   https://dev.azure.com/slb-des-ext-collaboration/open-data-ecosystem/_backlogs/backlog/microsoft-open-data-ecosystem/Stories/?workitem=755
  )

  storage_role_principals = [
    module.authn_app_service.app_service_identity_config_data[local.storage_app_name],
    module.authn_app_service.app_service_identity_config_data[local.legal_app_name],
    module.app_management_service_principal.service_principal_object_id
  ]

  service_bus_role_principals = [
    module.authn_app_service.app_service_identity_config_data[local.storage_app_name],
    module.authn_app_service.app_service_identity_config_data[local.legal_app_name],
    module.authn_app_service.app_service_identity_config_data[local.indexer_app_name],
    module.app_management_service_principal.service_principal_object_id
  ]
}

module "app_management_service_principal" {
  source          = "../../modules/providers/azure/service-principal"
  create_for_rbac = true
  display_name    = local.ad_app_management_name
  role_name       = "Contributor"
  role_scopes     = local.rbac_contributor_scopes
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
