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


variable "prefix" {
  description = "(Required) An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 4
}

variable "data_resources_workspace_name" {
  description = "(Required) The workspace name for the data_resources terraform environment / template to reference for this template."
  type        = string
}

variable "remote_state_account" {
  description = "Remote Terraform State Azure storage account name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "remote_state_container" {
  description = "Remote Terraform State Azure storage container name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "common_resources_workspace_name" {
  description = "(Required) The workspace name for the common_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "resource_group_location" {
  description = "(Required) The Azure region where all resources in this template should be created."
  type        = string
}

variable "dns_name" {
  description = "Default DNS Name for the Public IP"
  type        = string
  default     = "osdu.contoso.com"
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_fe_prefix" {
  description = "The address prefix to use for the frontend subnet."
  type        = string
  default     = "10.10.1.0/26"
}

variable "subnet_aks_prefix" {
  description = "The address prefix to use for the aks subnet."
  type        = string
  default     = "10.10.2.0/24"
}

variable "subnet_be_prefix" {
  description = "The address prefix to use for the backend subnet."
  type        = string
  default     = "10.10.3.0/28"
}

variable "ssl_certificate_file" {
  type        = string
  description = "(Required) The x509-based SSL certificate used to setup ssl termination on the app gateway."
  default     = ""
}