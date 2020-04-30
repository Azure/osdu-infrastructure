resource "random_id" "entitlement_key" {
  byte_length = 18
}

module "keyvault" {
  source              = "../../../../modules/providers/azure/keyvault"
  keyvault_name       = local.kv_name
  resource_group_name = azurerm_resource_group.aks_rg.name
}

module "flex_volume" {
  source = "github.com/erikschlegel/bedrock?ref=aks_msi_integration//cluster/azure/keyvault_flexvol"

  resource_group_name          = azurerm_resource_group.aks_rg.name
  service_principal_id         = module.app_management_service_principal.service_principal_application_id
  service_principal_secret     = module.app_management_service_principal.service_principal_password
  tenant_id                    = local.tenant_id
  keyvault_name                = module.keyvault.keyvault_name
  flexvol_deployment_url       = var.flexvol_deployment_url
  kubeconfig_complete          = module.aks-gitops.kubeconfig_done
  aks_kv_identity_principal_id = module.aks-gitops.aks_user_identity_principal_id
}

module "aks_msi_keyvault_access_policy" {
  source    = "../../../../modules/providers/azure/keyvault-policy"
  vault_id  = module.keyvault.keyvault_id
  tenant_id = local.tenant_id
  object_ids = [
    module.app_management_service_principal.service_principal_object_id,
    module.aks-gitops.kubelet_client_id,
    module.aks-gitops.msi_client_id
  ]
  key_permissions         = ["get", "list"]
  secret_permissions      = ["get", "list"]
  certificate_permissions = ["get", "list"]
}

locals {
  secrets_map = {
    # AAD Application Secrets
    aad-client-id = module.ad_application.azuread_app_ids[0]
    # App Insights Secrets
    appinsights-key = module.app_insights.app_insights_instrumentation_key
    # Service Bus Namespace Secrets
    sb-connection = module.service_bus.service_bus_namespace_default_connection_string
    # Elastic Search Cluster Secrets
    elastic-endpoint = data.terraform_remote_state.data_sources.outputs.elastic_cluster_properties.elastic_search.endpoint
    elastic-username = data.terraform_remote_state.data_sources.outputs.elastic_cluster_properties.elastic_search.username
    elastic-password = data.terraform_remote_state.data_sources.outputs.elastic_cluster_properties.elastic_search.password
    # Cosmos Cluster Secrets
    cosmos-endpoint    = data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.endpoint
    cosmos-primary-key = data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.primary_master_key
    cosmos-connection  = data.terraform_remote_state.data_sources.outputs.cosmosdb_properties.cosmosdb.connection_strings[0]
    # App Service Auth Related Secrets
    entitlement-key = random_id.entitlement_key.hex
    # Service Principal Secrets
    app-dev-sp-username  = module.app_management_service_principal.service_principal_application_id
    app-dev-sp-password  = module.app_management_service_principal.service_principal_password
    app-dev-sp-tenant-id = data.azurerm_client_config.current.tenant_id
  }

  output_secret_map = {
    for secret in module.keyvault_secrets.keyvault_secret_attributes :
    secret.name => secret.id
  }
}

module "keyvault_secrets" {
  source      = "../../../../modules/providers/azure/keyvault-secret"
  keyvault_id = module.keyvault.keyvault_id
  secrets     = local.secrets_map
}
