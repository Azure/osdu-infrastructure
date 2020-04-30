locals {
  rbac_contributor_scopes = concat(
    # Keyvault
    [module.keyvault.keyvault_id],

    # The cosmosdb resource id
    [data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.id],

    # The storage resource id
    [data.terraform_remote_state.data_sources.outputs.storage_account_id],

    # The redis resource id
    [data.terraform_remote_state.data_sources.outputs.redis_resource_id],

    # The Container Registry Id
    [data.terraform_remote_state.image_repository.outputs.container_registry_id]
  )

  app_dev_principals = [
    module.app_management_service_principal.service_principal_object_id,
    module.aks-gitops.msi_client_id,
    module.aks-gitops.kubelet_client_id,
    module.aks-gitops.aks_user_identity_principal_id
  ]
}

data "azurerm_virtual_network" "aks_vnet" {
  name                = module.vnet.vnet_name
  resource_group_name = azurerm_resource_group.aks_rg.name
}

module "app_management_service_principal" {
  source          = "../../../../modules/providers/azure/service-principal"
  create_for_rbac = true
  display_name    = local.ad_app_management_name
  role_name       = "Contributor"
  role_scopes     = local.rbac_contributor_scopes
}

module "ad_application" {
  source               = "../../../../modules/providers/azure/ad-application"
  resource_access_type = "Scope"
  ad_app_config = [
    {
      app_name   = local.ad_app_name
      reply_urls = []
    }
  ]
  resource_app_id  = local.graph_id
  resource_role_id = local.graph_role_id
}

resource "azurerm_role_assignment" "aks_vnet" {
  count                = length(local.app_dev_principals)
  role_definition_name = "Network Contributor"
  principal_id         = local.app_dev_principals[count.index]
  scope                = data.azurerm_virtual_network.aks_vnet.id
}

resource "azurerm_role_assignment" "aks_group" {
  count                = length(local.app_dev_principals)
  role_definition_name = "Contributor"
  principal_id         = local.app_dev_principals[count.index]
  scope                = azurerm_resource_group.aks_rg.id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = length(local.app_dev_principals)
  role_definition_name = "AcrPull"
  principal_id         = local.app_dev_principals[count.index]
  scope                = data.terraform_remote_state.image_repository.outputs.container_registry_id
}

resource "azurerm_role_assignment" "storage_roles" {
  count                = length(local.app_dev_principals)
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.app_dev_principals[count.index]
  scope                = data.terraform_remote_state.data_sources.outputs.storage_account_id
}

resource "azurerm_role_assignment" "service_bus_roles" {
  count                = length(local.app_dev_principals)
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = local.app_dev_principals[count.index]
  scope                = module.service_bus.namespace_id
}
