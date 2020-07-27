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


terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}


#-------------------------------
# Providers  (main.tf)
#-------------------------------
provider "azurerm" {
  version = "~> 2.18.0"
  features {}
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

provider "local" {
  version = "~> 1.4"
}

provider "random" {
  version = "~> 2.3"
}


#-------------------------------
# Private Variables  (common.tf)
#-------------------------------
locals {
  // sanitize names
  prefix    = replace(trimspace(lower(var.prefix)), "_", "-")
  workspace = replace(trimspace(lower(terraform.workspace)), "-", "")
  suffix    = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""

  // base prefix for resources, prefix constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  tenant_id           = data.azurerm_client_config.current.tenant_id
  resource_group_name = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  storage_name        = "${replace(local.base_name_21, "-", "")}la"
  ai_name             = "${local.base_name}-ai"


  // security.tf
  kv_name       = "${local.base_name_21}-kv"
  ssl_cert_name = "appgw-ssl-cert"

  // network.tf
  vnet_name       = "${local.base_name_60}-vnet"
  fe_subnet_name  = "${local.base_name_21}-fe-subnet"
  aks_subnet_name = "${local.base_name_21}-aks-subnet"
  be_subnet_name  = "${local.base_name_21}-be-subnet"
  app_gw_name     = "${local.base_name_60}-gw"

  // cluster.tf
  aks_cluster_name = "${local.base_name_21}-aks"
  aks_dns_prefix   = local.base_name_60

  // WARNING: Unfortunately order here is important.  Only append to the map don't insert.
  secrets_map = {
    # Imported Secrets from State
    cosmos-endpoint     = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.endpoint
    cosmos-primary-key  = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.primary_master_key
    cosmos-connection   = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.connection_strings[0]
    storage-account-key = data.terraform_remote_state.data_resources.outputs.storage_properties.primary_access_key
    sb-connection       = data.terraform_remote_state.data_resources.outputs.sb_namespace_default_connection_string

    # Secrets from this template
    appinsights-key         = module.app_insights.app_insights_instrumentation_key
    diagnostics-account-key = module.storage_account.primary_access_key
  }
}


#-------------------------------
# Common Resources  (common.tf)
#-------------------------------
data "azurerm_client_config" "current" {}

data "terraform_remote_state" "data_resources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.data_resources_workspace_name)
  }
}

data "terraform_remote_state" "common_resources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.common_resources_workspace_name)
  }
}

resource "random_string" "workspace_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name    = replace(trimspace(lower(terraform.workspace)), "_", "-")
    cluster_id = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = max(1, var.randomization_level) // error for zero-length
  special = false
  upper   = false
}


#-------------------------------
# Resource Group
#-------------------------------
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_management_lock" "rg_lock" {
  name       = "osdu_ds_rg_lock"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
}

#-------------------------------
# Storage
#-------------------------------
module "storage_account" {
  source = "../../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = var.storage_containers
  kind                = "StorageV2"
  replication_type    = "LRS"
}

resource "azurerm_management_lock" "la_lock" {
  name       = "osdu_sr_la_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}


#-------------------------------
# Application Insights (main.tf)
#-------------------------------
module "app_insights" {
  source = "../../../../modules/providers/azure/app-insights"

  appinsights_name                 = local.ai_name
  service_plan_resource_group_name = azurerm_resource_group.main.name

  appinsights_application_type = "other"
}


#-------------------------------
# Network (main.tf)
#-------------------------------
module "network" {
  source = "../../../../modules/providers/azure/network"

  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
  dns_servers         = ["8.8.8.8"]
  subnet_prefixes     = [var.subnet_fe_prefix, var.subnet_aks_prefix, var.subnet_be_prefix]
  subnet_names        = [local.fe_subnet_name, local.aks_subnet_name, local.be_subnet_name]
}

module "appgateway" {
  source = "../../../../modules/providers/azure/aks-appgw"

  name                = local.app_gw_name
  resource_group_name = azurerm_resource_group.main.name

  vnet_name            = module.network.name
  vnet_subnet_id       = module.network.subnets.0
  keyvault_id          = module.keyvault.keyvault_id
  keyvault_secret_id   = azurerm_key_vault_certificate.default.0.secret_id # TODO: If not default then import
  ssl_certificate_name = local.ssl_cert_name
}


#-------------------------------
# Key Vault  (security.tf)
#-------------------------------
module "keyvault" {
  source = "../../../../modules/providers/azure/keyvault"

  keyvault_name       = local.kv_name
  resource_group_name = azurerm_resource_group.main.name
}

# Default Certificate Install.
resource "azurerm_key_vault_certificate" "default" {
  count = var.ssl_certificate_file == "" ? 1 : 0

  name         = local.ssl_cert_name
  key_vault_id = module.keyvault.keyvault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = [var.dns_name, "${local.base_name}-gw.${azurerm_resource_group.main.location}.cloudapp.azure.com"]
      }

      subject            = "CN=*.contoso.com"
      validity_in_months = 12
    }
  }
}

// Secrets Load from things created in this template.
// When this module runs depends upon the secrets loaded.
module "keyvault_secrets" {
  source      = "../../../../modules/providers/azure/keyvault-secret"
  keyvault_id = module.keyvault.keyvault_id
  secrets     = local.secrets_map
}


#-------------------------------
# Azure AKS  (cluster.tf)
#-------------------------------
module "aks-gitops" {
  source = "../../../../modules/providers/azure/aks-gitops"

  name                = local.aks_cluster_name
  resource_group_name = azurerm_resource_group.main.name

  dns_prefix         = local.aks_dns_prefix
  agent_vm_count     = var.aks_agent_vm_count
  agent_vm_size      = var.aks_agent_vm_size
  vnet_subnet_id     = module.network.subnets.1
  ssh_public_key     = file(var.ssh_public_key_file)
  kubernetes_version = var.kubernetes_version

  flux_recreate     = var.flux_recreate
  acr_enabled       = true
  gc_enabled        = true
  msi_enabled       = true
  oms_agent_enabled = true

  gitops_ssh_url       = var.gitops_ssh_url
  gitops_ssh_key       = var.gitops_ssh_key_file
  gitops_url_branch    = var.gitops_config.branch
  gitops_path          = var.gitops_config.path
  gitops_poll_interval = var.gitops_config.interval
  gitops_label         = var.gitops_config.label
}

provider "kubernetes" {
  version                = "~> 1.11.3"
  load_config_file       = false
  host                   = module.aks-gitops.kube_config.0.host
  username               = module.aks-gitops.kube_config.0.username
  password               = module.aks-gitops.kube_config.0.password
  client_certificate     = base64decode(module.aks-gitops.kube_config.0.client_certificate)
  client_key             = base64decode(module.aks-gitops.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks-gitops.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  version = "~> 1.2.3"

  kubernetes {
    load_config_file       = false
    host                   = module.aks-gitops.kube_config.0.host
    username               = module.aks-gitops.kube_config.0.username
    password               = module.aks-gitops.kube_config.0.password
    client_certificate     = base64decode(module.aks-gitops.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks-gitops.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks-gitops.kube_config.0.cluster_ca_certificate)
  }
}

data "azurerm_resource_group" "aks_node_resource_group" {
  name = module.aks-gitops.node_resource_group
}