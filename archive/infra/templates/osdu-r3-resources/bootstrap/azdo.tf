/*
.Synopsis
   Terraform Main Control
.DESCRIPTION
   This file holds the main control and resoures for bootstraping an OSDU Azure Devops Project.
*/

terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}


#-------------------------------
# Providers
#-------------------------------
provider "azuredevops" {
  version = ">= 0.0.1"
}

provider "null" {
  version = "2.1.2"
}

data "azuredevops_projects" "p" {
  project_name = var.project_name
}


#-------------------------------
# Application Variables  (variables.tf)
#-------------------------------
variable "environments" {
  description = "Environments and the list of properties that are specific to each environment"
  type = list(object({
    environment                     = string,
    az_sub_id                       = string,
    aks_agent_vm_count              = string,
    cosmosdb_replica_location       = string,
    data_sources_workspace          = string,
    flux_recreate                   = string,
    gitops_ssh_url                  = string,
    gitops_url_branch               = string,
    gitops_path                     = string,
    image_repository_workspace_name = string,
    ssl_certificate_keyvault_id     = string,
    ssl_keyvault_id                 = string,
    service_connection_name         = string
  }))
}

variable "project_name" {
  description = "The name of an existing project that will be provisioned to run the IaC CI/CD pipelines"
  type        = string
}

variable "project_id" {
  description = "The id of an existing project that will be provisioned to run the IaC CI/CD pipelines"
  type        = string
}

variable "service_connection_name" {
  description = "The name of the service connection used for the templates"
  type        = string
}

variable "remote_state_account" {
  description = "The name of the remote Terraform state account"
  type        = string
}

variable "remote_state_container" {
  description = "The name of the remote Terraform state container"
  type        = string
}

variable "agent_pool" {
  description = "The name and configuration for the agent pool"
  type        = string
  default     = "Hosted Ubuntu 1604"
}

variable "resource_group_location" {
  description = "The Azure region where all resources in this template should be created."
  type        = string
}

variable "build_artifact_name" {
  description = "Name of build artifact"
  type        = string
  default     = "infra-templates-evd"
}

variable "force_run" {
  description = "Force run"
  type        = string
  default     = "False"
}

variable "randomization_level" {
  description = "Level of Randomization setting"
  type        = string
  default     = "8"
}

variable "warn_output_errors" {
  description = "Warn Output Error setting"
  type        = string
  default     = "True"
}

variable "cosmosdb_consistency_level" {
  description = "CosmoDB consistency level setting"
  type        = string
  default     = "Session"
}

variable "cosmosdb_throughput" {
  description = ""
  type        = string
  default     = "400"
}

variable "cosmosdb_replica_location" {
  description = "CosmoDB replica location setting"
  type        = string
}


#-------------------------------
# Private Variables  (common.tf)
#-------------------------------
locals {
  project_name = data.azuredevops_projects.p.project_name
  project_id   = data.azuredevops_projects.p.projects.*.project_id[0]
}


#-------------------------------
# Azure DevOps
#-------------------------------
resource "azuredevops_variable_group" "cc_core_vg" {
  project_id   = local.project_id
  name         = "osducc Variables"
  description  = "Variables used by the infrastructure-template repo pipelines."
  allow_access = true

  variable {
    name  = "AGENT_POOL"
    value = var.agent_pool
  }

  variable {
    name  = "SERVICE_CONNECTION_NAME"
    value = var.service_connection_name
  }

  variable {
    name  = "TF_VAR_prefix"
    value = "cc"
  }

  variable {
    name  = "TF_VAR_remote_state_account"
    value = var.remote_state_account
  }

  variable {
    name  = "TF_VAR_remote_state_container"
    value = var.remote_state_container
  }
}

resource "azuredevops_variable_group" "ir_core_vg" {
  project_id   = local.project_id
  name         = "osduir Variables"
  description  = "Variables used by the infrastructure-template repo pipelines."
  allow_access = true

  variable {
    name  = "AGENT_POOL"
    value = var.agent_pool
  }

  variable {
    name  = "SERVICE_CONNECTION_NAME"
    value = var.service_connection_name
  }

  variable {
    name  = "TF_VAR_prefix"
    value = "ir"
  }

  variable {
    name  = "TF_VAR_remote_state_account"
    value = var.remote_state_account
  }

  variable {
    name  = "TF_VAR_remote_state_container"
    value = var.remote_state_container
  }

  variable {
    name  = "BUILD_ARTIFACT_NAME"
    value = var.build_artifact_name # REC'D BE MOVED TO ENVIRONMENT
  }

  variable {
    name  = "environment"
    value = "r3demo" # REC'D BE MOVED TO ENVIRONMENT, hardcoded for now
  }

  variable {
    name  = "FORCE_RUN"
    value = var.force_run
  }

  variable {
    name  = "TF_VAR_randomization_level"
    value = var.randomization_level
  }

  variable {
    name  = "TF_VAR_resource_group_location"
    value = var.resource_group_location # REC'D BE MOVED TO ENVIRONMENT
  }

  variable {
    name  = "TF_WARN_OUTPUT_ERRORS"
    value = var.warn_output_errors
  }
}

resource "azuredevops_variable_group" "ds_core_vg" {
  project_id   = local.project_id
  name         = "osduds Variables"
  description  = "Variables used by the infrastructure-template repo pipelines."
  allow_access = true

  variable {
    name  = "AGENT_POOL"
    value = var.agent_pool
  }

  variable {
    name  = "SERVICE_CONNECTION_NAME"
    value = var.service_connection_name
  }

  variable {
    name  = "TF_VAR_prefix"
    value = "ds"
  }

  variable {
    name  = "TF_VAR_remote_state_account"
    value = var.remote_state_account
  }

  variable {
    name  = "TF_VAR_remote_state_container"
    value = var.remote_state_container
  }

  variable {
    name  = "TF_VAR_resource_group_location"
    value = var.resource_group_location # REC'D BE MOVED TO ENVIRONMENT
  }

  variable {
    name  = "TF_WARN_OUTPUT_ERRORS"
    value = var.warn_output_errors
  }

  variable {
    name  = "BUILD_ARTIFACT_NAME"
    value = var.build_artifact_name #  REC'D BE MOVED TO ENVIRONMENT
  }

  variable {
    name  = "FORCE_RUN"
    value = var.force_run
  }

  variable {
    name  = "TF_VAR_randomization_level"
    value = var.randomization_level
  }

  variable {
    name  = "TF_VAR_cosmosdb_replica_location"
    value = var.cosmosdb_replica_location #  REC'D BE MOVED TO ENVIRONMENT
  }

  variable {
    name  = "TF_VAR_cosmosdb_consistency_level"
    value = var.cosmosdb_consistency_level
  }

  variable {
    name  = "TF_VAR_cosmosdb_throughput"
    value = var.cosmosdb_throughput
  }
}

resource "azuredevops_variable_group" "cc_env_vg" {
  project_id   = local.project_id
  count        = length(var.environments)
  name         = format("osducc Variables - %s", var.environments[count.index].environment)
  description  = "Infrastructure Templates Env Specific Variables"
  allow_access = true

  variable {
    name  = "ARM_SUBSCRIPTION_ID"
    value = var.environments[count.index].az_sub_id
  }

  variable {
    name  = "REMOTE_STATE_ACCOUNT"
    value = var.remote_state_account
  }

  variable {
    name  = "REMOTE_STATE_CONTAINER"
    value = var.remote_state_container
  }

  variable {
    name  = "SERVICE_CONNECTION_NAME"
    value = var.service_connection_name
  }

  variable {
    name  = "TF_VAR_data_sources_workspace"
    value = var.environments[count.index].data_sources_workspace
  }

  variable {
    name  = "TF_VAR_aks_agent_vm_count"
    value = var.environments[count.index].aks_agent_vm_count
  }

  variable {
    name  = "TF_VAR_cosmosdb_replica_location"
    value = var.environments[count.index].cosmosdb_replica_location
  }

  variable {
    name  = "TF_VAR_flux_recreate"
    value = var.environments[count.index].flux_recreate
  }

  variable {
    name  = "TF_VAR_gitops_path"
    value = var.environments[count.index].gitops_path
  }

  variable {
    name  = "TF_VAR_gitops_ssh_url"
    value = var.environments[count.index].gitops_ssh_url
  }

  variable {
    name  = "TF_VAR_gitops_url_branch"
    value = var.environments[count.index].gitops_url_branch
  }

  variable {
    name  = "TF_VAR_image_repository_workspace_name"
    value = var.environments[count.index].image_repository_workspace_name
  }

  variable {
    name  = "TF_VAR_resource_group_location"
    value = var.resource_group_location
  }

  variable {
    name  = "TF_VAR_ssl_certificate_keyvault_id"
    value = var.environments[count.index].ssl_certificate_keyvault_id
  }

  variable {
    name  = "TF_VAR_ssl_keyvault_id"
    value = var.environments[count.index].ssl_keyvault_id
  }
}

resource "azuredevops_variable_group" "ir_env_vg" {
  project_id   = local.project_id
  count        = length(var.environments)
  name         = format("osduir Variables - %s", var.environments[count.index].environment)
  description  = "Infrastructure Templates Env Specific Variables"
  allow_access = true

  variable {
    name  = "ARM_SUBSCRIPTION_ID"
    value = var.environments[count.index].az_sub_id
  }
  variable {
    name  = "SERVICE_CONNECTION_NAME"
    value = var.environments[count.index].service_connection_name
  }

}

resource "azuredevops_variable_group" "ds_env_vg" {
  project_id   = local.project_id
  count        = length(var.environments)
  name         = format("osduds Variables - %s", var.environments[count.index].environment)
  description  = "Infrastructure Templates Env Specific Variables"
  allow_access = true

  variable {
    name  = "ARM_SUBSCRIPTION_ID"
    value = var.environments[count.index].az_sub_id
  }
  variable {
    name  = "SERVICE_CONNECTION_NAME"
    value = var.environments[count.index].service_connection_name
  }
}

resource "azuredevops_variable_group" "cc_secrets_vg" {
  project_id   = local.project_id
  count        = length(var.environments)
  name         = format("osducc Secrets - %s", var.environments[count.index].environment)
  description  = "Infrastructure Templates Env Specific Secrets"
  allow_access = true

  variable {
    name      = "PLACEHOLDER"
    value     = "placeholder"
    is_secret = true
  }
}

resource "azuredevops_variable_group" "ds_secrets_vg" {
  project_id   = local.project_id
  count        = length(var.environments)
  name         = format("osduds Secrets - %s", var.environments[count.index].environment)
  description  = "Infrastructure Templates Env Specific Secrets"
  allow_access = true

  variable {
    name      = "PLACEHOLDER"
    value     = "placeholder"
    is_secret = true
  }
}

resource "azuredevops_variable_group" "ir_secrets_vg" {
  project_id   = local.project_id
  count        = length(var.environments)
  name         = format("osduir Secrets - %s", var.environments[count.index].environment)
  description  = "Infrastructure Templates Env Specific Secrets"
  allow_access = true

  variable {
    name      = "PLACEHOLDER"
    value     = "placeholder"
    is_secret = true
  }
}