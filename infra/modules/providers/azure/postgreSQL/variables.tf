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

#Dependent Services (Required)

variable "resource_group_name" {
    description = "The name of the resource group postgreSQL VM will be created in"
    type = string
}

/* variable "virtual_network_name" {
    description = "Name of the virtual network the VM will use"
    type = string
}

variable "subnet_name" {
    description = "Name of the subnet the virtual network will use"
    type = string
} */

# Naming Conventions (required)

variable "db_name" {
    description = "The name of the postgresql db being created"
    type = string
}

variable "server_name" {
    description = "The name of the postgresql server being created"
    type = string
}

variable "admin_user" {
    description = "Username of admin account"
    type = string
}

variable "admin_password" {
    description = "Pass of admin account"
    type = string
}

# Configuration Variables (Optional)

variable "public_network_access" {
    description = "Enable or Disable public network access to the VM"
    type = bool
    default = false
}

variable "storage_mb" {
    description = "Amount of storage in mb"
    type = number
    default = 640000
}

variable "sku" {
    description = "Name of the sku"
    type = string
    default = "GP_Gen5_4"
}

variable "server_version" {
    description = "Version number. Either 9.5 or 9.6"
    type = string
    default = "9.6"
}

variable "backup_retention_days" {
    description = "Number of days to retain backup data"
    type = number
    default = 7
}

variable "geo_redundant_backup_enabled" {
    description = "Enable geo-redundancy"
    type = bool
    default = false
}

variable "auto_grow_enabled" {
    description = "Enable auto grow"
    type = bool
    default = true
}

variable "ssl_enforcement_enabled" {
    description = "Enable ssl enforcement"
    type = bool
    default = true
}