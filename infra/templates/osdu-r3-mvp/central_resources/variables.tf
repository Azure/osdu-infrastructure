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
   Terraform Variable Configuration
.DESCRIPTION
   This file holds the Variable Configuration
*/


#-------------------------------
# Application Variables
#-------------------------------
variable "prefix" {
  description = "(Required) An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 4
}

variable "resource_group_location" {
  description = "The Azure region where container registry resources in this template should be created."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs."
  type        = number
  default     = 30
}

variable "container_registry_sku" {
  description = "(Optional) The SKU name of the the container registry. Possible values are Basic, Standard and Premium."
  type        = string
  default     = "Standard"
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

variable "principal_name" {
  description = "Existing Service Principal Name."
  type        = string
}

variable "principal_password" {
  description = "Existing Service Principal Password."
  type        = string
}

variable "principal_appId" {
  description = "Existing Service Principal AppId."
  type        = string
}

variable "principal_objectId" {
  description = "Existing Service Principal ObjectId."
  type        = string
}

variable "storage_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS*, GRS, RAGRS and ZRS."
  type        = string
  default     = "LRS"
}