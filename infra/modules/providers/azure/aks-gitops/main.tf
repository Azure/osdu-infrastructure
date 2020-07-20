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

data "azurerm_resource_group" "aksgitops" {
  name = var.resource_group_name
}

module "aks" {
  source = "../aks"

  name                     = var.name
  resource_group_name      = data.azurerm_resource_group.aksgitops.name
  resource_tags            = var.resource_tags

  agent_vm_count           = var.agent_vm_count
  agent_vm_size            = var.agent_vm_size
  ssh_public_key           = var.ssh_public_key
  kubernetes_version       = var.kubernetes_version
  kubeconfig_filename      = var.kubeconfig_filename

  dns_prefix               = var.dns_prefix
  vnet_subnet_id           = var.vnet_subnet_id
  network_policy           = var.network_policy
  network_plugin           = var.network_plugin
  dns_ip                   = var.dns_ip
  docker_cidr              = var.docker_cidr
  service_cidr             = var.service_cidr

  msi_enabled              = var.msi_enabled
  service_principal_id     = var.service_principal_id
  service_principal_secret = var.service_principal_secret

  oms_agent_enabled        = var.oms_agent_enabled
}

module "flux" {
  source = "../flux"

  gitops_ssh_url       = var.gitops_ssh_url
  gitops_ssh_key_path  = var.gitops_ssh_key
  gitops_path          = var.gitops_path
  gitops_poll_interval = var.gitops_poll_interval
  gitops_label         = var.gitops_label
  gitops_url_branch    = var.gitops_url_branch
  enable_flux          = var.enable_flux
  flux_recreate        = var.flux_recreate
  kubeconfig_complete  = module.aks.kubeconfig_done
  kubeconfig_filename  = var.kubeconfig_filename
  flux_clone_dir       = "${var.name}-flux"
  acr_enabled          = var.acr_enabled
  gc_enabled           = var.gc_enabled
}

module "kubediff" {
  source = "../kubediff"

  kubeconfig_complete = module.aks.kubeconfig_done
  gitops_ssh_url      = var.gitops_ssh_url
}