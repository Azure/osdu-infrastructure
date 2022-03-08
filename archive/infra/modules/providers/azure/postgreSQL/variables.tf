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

# Naming Conventions (required)

variable "name" {
  description = "The name of the postgresql db being created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group postgreSQL VM will be created in"
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "The list of names of the PostgreSQL Database, which needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created."
  default     = []
}

variable "admin_user" {
  description = "The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created."
  type        = string
}

variable "admin_password" {
  description = "The Password associated with the administrator_login for the PostgreSQL Server."
  type        = string
}

# Configuration Variables (Optional)
variable "sku" {
  description = "Name of the sku"
  type        = string
  default     = "GP_Gen5_4"
}

variable "storage_mb" {
  description = "Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB)."
  type        = number
  default     = 5120
}

variable "server_version" {
  description = "Specifies the version of PostgreSQL to use. Valid values are 9.5, 9.6, and 10.0. Changing this forces a new resource to be created."
  type        = string
  default     = "10.0"
}

variable "backup_retention_days" {
  description = "Number of days to retain backup data"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundancy"
  type        = bool
  default     = true
}

variable "auto_grow_enabled" {
  description = "Enable auto grow"
  type        = bool
  default     = true
}

variable "ssl_enforcement_enabled" {
  description = "Enable ssl enforcement"
  type        = bool
  default     = true
}

variable "public_network_access" {
  description = "Enable or Disable public network access to the VM"
  type        = bool
  default     = false
}

variable "db_charset" {
  description = "Specifies the Charset for the PostgreSQL Database, which needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created."
  default     = "UTF8"
}

variable "db_collation" {
  description = "Specifies the Collation for the PostgreSQL Database, which needs to be a valid PostgreSQL Collation. Note that Microsoft uses different notation - en-US instead of en_US. Changing this forces a new resource to be created."
  default     = "English_United States.1252"
}

variable "firewall_rule_prefix" {
  description = "Specifies prefix for firewall rule names."
  default     = "firewall-"
}

variable "firewall_rules" {
  description = "The list of maps, describing firewall rules. Valid map items: name, start_ip, end_ip."
  default     = []
}

variable "vnet_rule_name_prefix" {
  description = "Specifies prefix for vnet rule names."
  default     = "postgresql-vnet-rule-"
}

variable "vnet_rules" {
  description = "The list of maps, describing vnet rules. Valud map items: name, subnet_id."
  default     = []
}

variable "postgresql_configurations" {
  description = "A map with PostgreSQL configurations to enable."
  type        = map(string)
  default     = {}
}