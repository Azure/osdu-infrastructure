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

resource "azurerm_resource_group" "aks_rg" {
  name     = local.aks_rg_name
  location = local.region
}

module "aks-gitops" {
  source = "github.com/erikschlegel/bedrock?ref=msi_support//cluster/azure/aks-gitops"

  acr_enabled          = true
  agent_vm_count       = var.aks_agent_vm_count
  agent_vm_size        = var.aks_agent_vm_size
  cluster_name         = local.aks_cluster_name
  dns_prefix           = local.aks_dns_prefix
  flux_recreate        = var.flux_recreate
  gc_enabled           = true
  msi_enabled          = true
  gitops_ssh_url       = var.gitops_ssh_url
  gitops_ssh_key       = var.gitops_ssh_key_file
  gitops_path          = var.gitops_path
  gitops_poll_interval = var.gitops_poll_interval
  gitops_label         = var.gitops_label
  gitops_url_branch    = var.gitops_url_branch
  kubernetes_version   = var.kubernetes_version
  resource_group_name  = azurerm_resource_group.aks_rg.name
  ssh_public_key       = file(var.ssh_public_key_file)
  vnet_subnet_id       = azurerm_subnet.aks.id
  network_plugin       = var.network_plugin
  network_policy       = var.network_policy
  oms_agent_enabled    = var.oms_agent_enabled
}

module "app_insights" {
  source                           = "../../../../modules/providers/azure/app-insights"
  service_plan_resource_group_name = azurerm_resource_group.aks_rg.name
  appinsights_name                 = local.ai_name
  appinsights_application_type     = "other"
}

## Service Bus
module "service_bus" {
  source              = "../../../../modules/providers/azure/service-bus"
  namespace_name      = local.sb_namespace
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = var.sb_sku
  topics              = var.sb_topics
}