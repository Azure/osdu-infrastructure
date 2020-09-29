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
   This file holds the Default Variable Configuration
*/

prefix = "osdu-mvp"

resource_tags = {
  contact = "pipeline"
}

# Storage Settings
storage_replication_type = "GZRS"
storage_containers = [
  "legal-service-azure-configuration",
  "opendes",
  "osdu-wks-mappings"
]


# Database Settings
cosmosdb_consistency_level = "Session"
cosmos_databases = [
  {
    name       = "osdu-db"
    throughput = 4000
  }
]
cosmos_sql_collections = [
  {
    name               = "LegalTag"
    database_name      = "osdu-db"
    partition_key_path = "/id"
  },
  {
    name               = "StorageRecord"
    database_name      = "osdu-db"
    partition_key_path = "/id"
  },
  {
    name               = "StorageSchema"
    database_name      = "osdu-db"
    partition_key_path = "/kind"
  },
  {
    name               = "TenantInfo"
    database_name      = "osdu-db"
    partition_key_path = "/id"
  },
  {
    name               = "UserInfo"
    database_name      = "osdu-db"
    partition_key_path = "/id"
  },
  {
    name               = "Authority"
    database_name      = "osdu-db"
    partition_key_path = "/dataPartitionId"
  },
  {
    name               = "EntityType"
    database_name      = "osdu-db"
    partition_key_path = "/dataPartitionId"
  },
  {
    name               = "SchemaInfo"
    database_name      = "osdu-db"
    partition_key_path = "/dataPartitionId"
  },
  {
    name               = "Source"
    database_name      = "osdu-db"
    partition_key_path = "/dataPartitionId"
  },
  {
    name               = "RegisterAction"
    database_name      = "osdu-db"
    partition_key_path = "/dataPartitionId"
  },
  {
    name               = "RegisterDdms"
    database_name      = "osdu-db"
    partition_key_path = "/dataPartitionId"
  },
  {
    name               = "RegisterSubscription"
    database_name      = "osdu-db"
    partition_key_path = "/dataPartitionId"
  }
]


# Service Bus Settings
sb_topics = [
  {
    name                = "indexing-progress"
    enable_partitioning = true
    subscriptions = [
      {
        name               = "indexing-progresssubscription"
        max_delivery_count = 5
        lock_duration      = "PT5M"
        forward_to         = ""
      }
    ]
  },
  {
    name                = "legaltags"
    enable_partitioning = true
    subscriptions = [
      {
        name               = "compliance-change--integration-test"
        max_delivery_count = 1
        lock_duration      = "PT5M"
        forward_to         = ""
      },
      {
        name               = "legaltagsubscription"
        max_delivery_count = 5
        lock_duration      = "PT5M"
        forward_to         = ""
      }
    ]
  },
  {
    name                = "recordstopic"
    enable_partitioning = true
    subscriptions = [
      {
        name               = "recordstopicsubscription"
        max_delivery_count = 5
        lock_duration      = "PT5M"
        forward_to         = ""
      },
      {
        name               = "wkssubscription"
        max_delivery_count = 5
        lock_duration      = "PT5M"
        forward_to         = ""
      }
    ]
  },
  {
    name                = "recordstopicdownstream"
    enable_partitioning = true
    subscriptions = [
      {
        name               = "downstreamsub"
        max_delivery_count = 5
        lock_duration      = "PT5M"
        forward_to         = ""
      }
    ]
  }
]