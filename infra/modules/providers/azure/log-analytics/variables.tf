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

##############################################################
# This module allows the creation of a Virtual Network
##############################################################

variable "name" {
  description = "Name of Log Analystics Workspace."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group the resource will be created in"
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "Sku of the Log Analytics Workspace."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "The workspace data retention in days. Between 30 and 730."
  default     = 30
}

variable "security_center_subscription" {
  description = "List of subscriptions this log analytics should collect data for."
  type        = list(string)
  default     = []
}

variable "solutions" {
  description = "A list of solutions to add to the workspace."
  type        = list(object({ solution_name = string, publisher = string, product = string }))
  default     = []
}