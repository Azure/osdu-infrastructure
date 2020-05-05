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

module "provider" {
  source = "../../../../modules/providers/azure/provider"
}

locals {
  prefix = "osdu"
}

resource "random_string" "naming_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name = replace(trimspace(lower(terraform.workspace)), "-", "")
    prefix  = replace(trimspace(lower(local.prefix)), "_", "-")
  }

  length  = 4
  special = false
  upper   = false
}

locals {
  // sanitize names
  resource_prefix = replace(format("%s-%s-%s", trimspace(lower(local.prefix)), trimspace(lower(terraform.workspace)), random_string.naming_scope.result), "_", "-")

  throughput          = 400
  data_rg_name        = "${local.resource_prefix}-data-rg"             // app resource group (max 90 chars)
  cache_name          = "${local.resource_prefix}-redis"               // redis cache
  storage_name        = "${replace(local.resource_prefix, "-", "")}sa" // storage account
  elastic_search_name = "${local.resource_prefix}-es"                  // elastic search deployment
  cosmosdb_name       = "${local.resource_prefix}-cosmosdb"            // cosmosdb account (max 44 chars )  
  cosmos_database = {
    name       = var.cosmos_db_name
    throughput = local.throughput
  }

  cosmos_sql_collections = [
    {
      name               = "LegalTag"
      database_name      = var.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "StorageRecord"
      database_name      = var.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "StorageSchema"
      database_name      = var.cosmos_db_name
      partition_key_path = "/kind"
      throughput         = local.throughput
    },
    {
      name               = "TenantInfo"
      database_name      = var.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "UserInfo"
      database_name      = var.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    }
  ]
}