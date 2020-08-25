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

  tenant_id              = data.azurerm_client_config.current.tenant_id
  resource_group_name    = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  ad_app_management_name = "${local.base_name}-tester"
  ad_app_name            = "${local.base_name}-app"
  storage_name           = "${replace(local.base_name_21, "-", "")}diag"
  storage_key_name       = "diagnostics-account-key"
  ai_name                = "${local.base_name}-ai"
  ai_key_name            = "appinsights-key"

  redis_cache_name  = "${local.base_name}-cache"
  postgresql_name   = "${local.base_name}-pg"
  postgres_password = coalesce(var.postgres_password, random_password.redis[0].result)

  // security.tf
  kv_name       = "${local.base_name_21}-kv"
  ssl_cert_name = "appgw-ssl-cert"

  rbac_principals = [
    azurerm_user_assigned_identity.osduidentity.principal_id,
    module.app_management_service_principal.id
  ]

  rbac_contributor_scopes = concat(
    # The cosmosdb resource id
    [data.terraform_remote_state.data_resources.outputs.cosmosdb_account_id],

    # The storage resource id
    [module.storage_account.id, data.terraform_remote_state.data_resources.outputs.storage_account_id],

    # The Container Registry Id
    [data.terraform_remote_state.common_resources.outputs.container_registry_id],
  )

  // network.tf
  vnet_name           = "${local.base_name_60}-vnet"
  fe_subnet_name      = "${local.base_name_21}-fe-subnet"
  aks_subnet_name     = "${local.base_name_21}-aks-subnet"
  be_subnet_name      = "${local.base_name_21}-be-subnet"
  app_gw_name         = "${local.base_name_60}-gw"
  appgw_identity_name = format("%s-agic-identity", local.app_gw_name)

  // cluster.tf
  aks_cluster_name      = "${local.base_name_21}-aks"
  aks_identity_name     = format("%s-pod-identity", local.aks_cluster_name)
  aks_dns_prefix        = local.base_name_60
  osdupod_identity_name = "${local.aks_cluster_name}-osdu-identity"
}



#-------------------------------
# Common Resources  (common.tf)
#-------------------------------
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

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

  lifecycle {
    ignore_changes = [tags]
  }
}


#-------------------------------
# AD Principal and Applications
#-------------------------------
module "app_management_service_principal" {
  source          = "../../../../modules/providers/azure/service-principal"
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

// Add Principal Information to KV
resource "azurerm_key_vault_secret" "principal_id" {
  name         = "app-dev-sp-username"
  value        = module.app_management_service_principal.client_id
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "principal_pwd" {
  name         = "app-dev-sp-password"
  value        = module.app_management_service_principal.client_secret
  key_vault_id = module.keyvault.keyvault_id
}

module "ad_application" {
  source                     = "../../../../modules/providers/azure/ad-application"
  name                       = local.ad_app_name
  oauth2_allow_implicit_flow = true

  reply_urls = [
    "http://localhost:8080",
    "http://localhost:8080/auth/callback"
  ]

  api_permissions = [
    {
      name = "Microsoft Graph"
      oauth2_permissions = [
        "User.Read"
      ]
    }
  ]
}

// Add Application Information to KV
resource "azurerm_key_vault_secret" "application_id" {
  name         = "aad-client-id"
  value        = module.ad_application.id
  key_vault_id = module.keyvault.keyvault_id
}



#-------------------------------
# Key Vault  (security.tf)
#-------------------------------
# TODO: Remove this section when storing of these secrets is moved to the data partition setup (https://github.com/Azure/osdu-infrastructure/issues/103)

module "keyvault" {
  source = "../../../../modules/providers/azure/keyvault"

  keyvault_name       = local.kv_name
  resource_group_name = azurerm_resource_group.main.name

  secrets = {
    cosmos-connection   = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.connection_strings[0]
    cosmos-endpoint     = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.endpoint
    cosmos-primary-key  = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.primary_master_key
    sb-connection       = data.terraform_remote_state.data_resources.outputs.sb_namespace_default_connection_string
    storage-account-key = data.terraform_remote_state.data_resources.outputs.storage_properties.primary_access_key
    elastic-endpoint    = var.elasticsearch_endpoint
    elastic-username    = var.elasticsearch_username
    elastic-password    = var.elasticsearch_password
    postgres-password   = local.postgres_password
  }
}

# Create a Default SSL Certificate.
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

// Add Tenant information to KV
resource "azurerm_key_vault_secret" "tenant_id" {
  name         = "app-dev-sp-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = module.keyvault.keyvault_id
}

module "keyvault_policy" {
  source             = "../../../../modules/providers/azure/keyvault-policy"
  vault_id           = module.keyvault.keyvault_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_ids         = local.rbac_principals
  secret_permissions = ["get"]
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

// Add the Storage Key to the Vault
resource "azurerm_key_vault_secret" "storage" {
  name         = local.storage_key_name
  value        = module.storage_account.primary_access_key
  key_vault_id = module.keyvault.keyvault_id
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

// Add the App Insights Key to the Vault
resource "azurerm_key_vault_secret" "ai" {
  name         = local.ai_key_name
  value        = module.app_insights.app_insights_instrumentation_key
  key_vault_id = module.keyvault.keyvault_id
}



#-------------------------------
# Azure Redis Cache (main.tf)
#-------------------------------

module "redis_cache" {
  source = "../../../../modules/providers/azure/redis-cache"

  name                = local.redis_cache_name
  resource_group_name = azurerm_resource_group.main.name
  capacity            = var.redis_capacity

  memory_features     = var.redis_config_memory
  premium_tier_config = var.redis_config_schedule
}

resource "azurerm_key_vault_secret" "redis_connection" {
  name         = "redis-connection"
  value        = module.app_management_service_principal.client_secret
  key_vault_id = module.keyvault.keyvault_id
}

#-------------------------------
# PostgreSQL (main.tf)
#-------------------------------

resource "random_password" "redis" {
  count = var.postgres_password == "" ? 1 : 0

  length           = 8
  special          = true
  override_special = "_%@"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

module "postgreSQL" {
  source = "../../../../modules/providers/azure/postgreSQL"

  resource_group_name       = azurerm_resource_group.main.name
  name                      = local.postgresql_name
  databases                 = var.postgres_databases
  admin_user                = var.postgres_username
  admin_password            = local.postgres_password
  sku                       = var.postgres_sku
  postgresql_configurations = var.postgres_configurations

  storage_mb                   = 5120
  server_version               = "10.0"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true
  ssl_enforcement_enabled      = true

  # Stuff for when we bring it in a network
  /*
  public_network_access = false
  firewall_rule_prefix = var.firewall_rule_prefix
  firewall_rules = var.firewall_rules
  vnet_rule_name_prefix = var.vnet_rule_name_prefix
  vnet_rules = var.vnet_rules 
  */

  # Stuff for when we bring it in a network
  /*   
  firewall_rules = [{
    start_ip = "10.0.0.2"
    end_ip   = "10.0.0.8"
  }]

  vnet_rules = [{
    subnet_id = module.network.subnets[0]
  }] 
  */
}


#-------------------------------
# Network (main.tf)
#-------------------------------
module "network" {
  source = "../../../../modules/providers/azure/network"

  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
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
  keyvault_secret_id   = azurerm_key_vault_certificate.default.0.secret_id
  ssl_certificate_name = local.ssl_cert_name
}

// Identity for AGIC
resource "azurerm_user_assigned_identity" "agicidentity" {
  name                = local.appgw_identity_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

// Managed Identity Operator role for AKS to AGIC Identity
resource "azurerm_role_assignment" "mi_ag_operator" {
  principal_id         = module.aks-gitops.kubelet_object_id
  scope                = azurerm_user_assigned_identity.agicidentity.id
  role_definition_name = "Managed Identity Operator"
}

// Contributor Role for AGIC to the AppGateway
resource "azurerm_role_assignment" "appgwcontributor" {
  principal_id         = azurerm_user_assigned_identity.agicidentity.principal_id
  scope                = module.appgateway.id
  role_definition_name = "Contributor"
}

// Reader Role for AGIC to the Resource Group
resource "azurerm_role_assignment" "agic_resourcegroup_reader" {
  principal_id         = azurerm_user_assigned_identity.agicidentity.principal_id
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
}

// Managed Identity Operator Role for AGIC to AppGateway Managed Identity
resource "azurerm_role_assignment" "agic_app_gw_mi" {
  principal_id         = azurerm_user_assigned_identity.agicidentity.principal_id
  scope                = module.appgateway.managed_identity_resource_id
  role_definition_name = "Managed Identity Operator"
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
  gitops_url_branch    = var.gitops_branch
  gitops_path          = var.gitops_path
  gitops_poll_interval = "10s"
  gitops_label         = "flux-sync"
}

data "azurerm_resource_group" "aks_node_resource_group" {
  name = module.aks-gitops.node_resource_group
}

// Identity for Pod Identity
resource "azurerm_user_assigned_identity" "podidentity" {
  name                = local.aks_identity_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

// Managed Identity Operator role for AKS to Node Resource Group
resource "azurerm_role_assignment" "all_mi_operator" {
  principal_id         = module.aks-gitops.kubelet_object_id
  scope                = data.azurerm_resource_group.aks_node_resource_group.id
  role_definition_name = "Managed Identity Operator"
}

// Virtual Machine Contributor role for AKS to Node Resource Group
resource "azurerm_role_assignment" "vm_contributor" {
  principal_id         = module.aks-gitops.kubelet_object_id
  scope                = data.azurerm_resource_group.aks_node_resource_group.id
  role_definition_name = "Virtual Machine Contributor"
}

// Azure Container Registry Reader role for AKS to ACR
resource "azurerm_role_assignment" "acr_reader" {
  principal_id         = module.aks-gitops.kubelet_object_id
  scope                = data.terraform_remote_state.common_resources.outputs.container_registry_id
  role_definition_name = "AcrPull"
}

// Managed Identity Operator role for AKS to Pod Identity
resource "azurerm_role_assignment" "mi_operator" {
  principal_id         = module.aks-gitops.kubelet_object_id
  scope                = azurerm_user_assigned_identity.podidentity.id
  role_definition_name = "Managed Identity Operator"
}



// Hook-up kubectl Provider for Terraform
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

// Hook-up helm Provider for Terraform
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



#-------------------------------
# OSDU Identity  (security.tf)
#-------------------------------
// Identity for OSDU Pod Identity
resource "azurerm_user_assigned_identity" "osduidentity" {
  name                = local.osdupod_identity_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "kv_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Reader"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.keyvault.keyvault_id
}

resource "azurerm_role_assignment" "database_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = local.rbac_principals[count.index]
  scope                = data.terraform_remote_state.data_resources.outputs.cosmosdb_account_id
}

resource "azurerm_role_assignment" "storage_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.rbac_principals[count.index]
  scope                = data.terraform_remote_state.data_resources.outputs.storage_account_id
}

resource "azurerm_role_assignment" "service_bus_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = local.rbac_principals[count.index]
  scope                = data.terraform_remote_state.data_resources.outputs.sb_namespace_id
}

// Managed Identity Operator role for AKS to the OSDU Identity
resource "azurerm_role_assignment" "osdu_identity_mi_operator" {
  principal_id         = module.aks-gitops.kubelet_object_id
  scope                = azurerm_user_assigned_identity.osduidentity.id
  role_definition_name = "Managed Identity Operator"
}


