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



// Need to be able to query the identityProfile to get kubelet client information. id, resourceid and client_id
locals {
  msi_identity_type = "SystemAssigned"
  log_analytics_id  = var.log_analytics_id == "" ? azurerm_log_analytics_workspace.main.0.id : var.log_analytics_id
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_subscription" "current" {}

resource "random_id" "main" {
  keepers = {
    group_name = data.azurerm_resource_group.main.name
  }

  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "main" {
  count = var.log_analytics_id == "" ? 1 : 0

  name                = lower("${var.name}")
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "main" {
  count = var.log_analytics_id == "" ? 1 : 0

  solution_name       = "ContainerInsights"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  workspace_resource_id = azurerm_log_analytics_workspace.main.0.id
  workspace_name        = azurerm_log_analytics_workspace.main.0.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  tags = var.resource_tags

  dns_prefix         = var.dns_prefix
  kubernetes_version = var.kubernetes_version

  linux_profile {
    admin_username = var.admin_user

    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  default_node_pool {
    name                = "default"
    node_count          = var.agent_vm_count
    vm_size             = var.agent_vm_size
    os_disk_size_gb     = 30
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = var.auto_scaling_default_node
    max_pods            = var.max_pods
    max_count           = var.auto_scaling_default_node == true ? var.max_node_count : null
    min_count           = var.auto_scaling_default_node == true ? var.agent_vm_count : null
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_ip
    docker_bridge_cidr = var.docker_cidr
  }

  role_based_access_control {
    enabled = true
  }

  dynamic "service_principal" {
    for_each = ! var.msi_enabled && var.service_principal_id != "" ? [{
      client_id     = var.service_principal_id
      client_secret = var.service_principal_secret
    }] : []
    content {
      client_id     = service_principal.value.client_id
      client_secret = service_principal.value.client_secret
    }
  }

  # This dynamic block enables managed service identity for the cluster
  # in the case that the following holds true:
  #   1: the msi_enabled input variable is set to true
  dynamic "identity" {
    for_each = var.msi_enabled ? [local.msi_identity_type] : []
    content {
      type = identity.value
    }
  }

  addon_profile {

    oms_agent {
      enabled                    = var.oms_agent_enabled
      log_analytics_workspace_id = local.log_analytics_id
    }

    # adding this as a patch to disable azurerm provider from redeploying due to unset
    # internal "optional value".  To be removed when azurerm provider is fixed.
    kube_dashboard {
      enabled = var.enable_kube_dashboard
    }
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      addon_profile[0].oms_agent[0].log_analytics_workspace_id
    ]
  }
}

