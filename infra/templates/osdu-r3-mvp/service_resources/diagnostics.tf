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


/*
.Synopsis
   Terraform Diagnostics Control
.DESCRIPTION
   This file holds diagnostics settings.
*/



#-------------------------------
# Network
#-------------------------------
resource "azurerm_monitor_diagnostic_setting" "vnet_diagnostics" {
  name                       = "vnet_diagnostics"
  target_resource_id         = module.network.id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id

  log {
    category = "VMProtectionAlerts"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }


  metric {
    category = "AllMetrics"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "gw_diagnostics" {
  name                       = "gw_diagnostics"
  target_resource_id         = module.appgateway.id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id


  log {
    category = "ApplicationGatewayAccessLog"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "ApplicationGatewayPerformanceLog"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "ApplicationGatewayFirewallLog"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }
}



#-------------------------------
# Azure AKS
#-------------------------------
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name                       = "aks_diagnostics"
  target_resource_id         = module.aks.id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id

  log {
    category = "cluster-autoscaler"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "guard"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "kube-apiserver"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "kube-audit"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "kube-audit-admin"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "kube-controller-manager"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "kube-scheduler"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }
}



#-------------------------------
# PostgreSQL
#-------------------------------
resource "azurerm_monitor_diagnostic_setting" "postgres_diagnostics" {
  name                       = "postgres_diagnostics"
  target_resource_id         = module.postgreSQL.server_id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id

  log {
    category = "PostgreSQLLogs"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }

  log {
    category = "QueryStoreRuntimeStatistics"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "QueryStoreWaitStatistics"

    retention_policy {
      enabled = false
    }
  }


  metric {
    category = "AllMetrics"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }
}



#-------------------------------
# Azure Redis Cache
#-------------------------------
resource "azurerm_monitor_diagnostic_setting" "redis_diagnostics" {
  name                       = "redis_diagnostics"
  target_resource_id         = module.redis_cache.id
  log_analytics_workspace_id = data.terraform_remote_state.central_resources.outputs.log_analytics_id


  metric {
    category = "AllMetrics"

    retention_policy {
      days    = var.log_retention_days
      enabled = local.retention_policy
    }
  }
}
