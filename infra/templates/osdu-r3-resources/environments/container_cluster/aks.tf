resource "azurerm_resource_group" "aks_rg" {
  name     = local.aks_rg_name
  location = local.region
}

module "aks-gitops" {
  source = "github.com/erikschlegel/bedrock?ref=aks_msi_integration//cluster/azure/aks-gitops"

  acr_enabled              = true
  agent_vm_count           = var.aks_agent_vm_count
  agent_vm_size            = var.aks_agent_vm_size
  cluster_name             = local.aks_cluster_name
  dns_prefix               = local.aks_dns_prefix
  flux_recreate            = var.flux_recreate
  gc_enabled               = true
  msi_enabled              = true
  gitops_ssh_url           = var.gitops_ssh_url
  gitops_ssh_key           = var.gitops_ssh_key_file
  gitops_path              = var.gitops_path
  gitops_poll_interval     = var.gitops_poll_interval
  gitops_label             = var.gitops_label
  gitops_url_branch        = var.gitops_url_branch
  kubernetes_version       = var.kubernetes_version
  resource_group_name      = azurerm_resource_group.aks_rg.name
  service_principal_id     = module.app_management_service_principal.service_principal_application_id
  service_principal_secret = module.app_management_service_principal.service_principal_password
  ssh_public_key           = file(var.ssh_public_key_file)
  vnet_subnet_id           = module.vnet.vnet_subnet_ids[0]
  network_plugin           = var.network_plugin
  network_policy           = var.network_policy
  oms_agent_enabled        = var.oms_agent_enabled
}

module "app_insights" {
  source                           = "../../../../modules/providers/azure/app-insights"
  service_plan_resource_group_name = azurerm_resource_group.aks_rg.name
  appinsights_name                 = local.ai_name
  appinsights_application_type     = "Web"
}

## Service Bus
module "service_bus" {
  source              = "../../../../modules/providers/azure/service-bus"
  namespace_name      = local.sb_namespace
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = var.sb_sku
  topics              = var.sb_topics
}
