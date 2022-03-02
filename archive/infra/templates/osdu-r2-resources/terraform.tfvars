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

# Note to developers: This file shows some examples that you may
# want to use in order to configure this template. It is your
# responsibility to choose the values that make sense for your application.
#
# Note: These values will impact the names of resources. If your deployment
# fails due to a resource name collision, consider using different values for
# the `prefix` variable or increasing the value for `randomization_level`.

prefix = "osdu-r2"

# Targets that will be configured to also setup AuthN with Easy Auth
app_services = [
  {
    app_name         = "legal"
    image            = null
    linux_fx_version = "JAVA|8-jre8"
    app_command_line = null
    app_settings = {
      legal_service_region  = "centralus"
      servicebus_topic_name = "legaltags"
    }
  },
  {
    app_name         = "entitlements"
    image            = null
    linux_fx_version = "JAVA|8-jre8"
    app_command_line = null
    app_settings = {
      service_domain_name = "contoso.com"
    }
  },
  {
    app_name         = "indexer"
    image            = null
    linux_fx_version = "JAVA|8-jre8"
    app_command_line = null
    app_settings = {
      servicebus_topic_name = "indexing-progress"
    }
  },
  {
    app_name         = "storage"
    image            = null
    linux_fx_version = "JAVA|8-jre8"
    app_command_line = null
    app_settings = {
      servicebus_topic_name = "recordstopic"
    }
  },
  {
    app_name         = "search"
    image            = null
    linux_fx_version = "JAVA|8-jre8"
    app_command_line = null
    app_settings = {
      "ELASTIC_CACHE_EXPIRATION"            = 1
      "MAX_CACHE_VALUE_SIZE"                = 60
      "ENVIRONMENT"                         = "evt"
      "azure.activedirectory.AppIdUri"      = "api://$${aad_client_id}"
      "search.service.spring.logging.level" = "DEBUG"
      "search.service.port"                 = 80
    }
  }
]

app_service_settings = {
  "JAVA_OPTS" = "-Dserver.port=80"
}

storage_containers = [
  "data",
  "legal-service-azure-configuration",
  "opendes"
]

function_apps = [
  {
    function_name = "enque"
    app_settings = {
      "FUNCTIONS_EXTENSION_VERSION"         = "~2",
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = false
      "FUNCTIONS_WORKER_RUNTIME"            = "java"
      "TOPIC_NAME"                          = "recordstopic"
    }
  }
]

sb_topics = [
  {
    name                         = "recordstopic"
    default_message_ttl          = "PT30M" //ISO 8601 format
    enable_partitioning          = false
    requires_duplicate_detection = true
    support_ordering             = true
    authorization_rules = [
      {
        policy_name = "policy"
        claims = {
          listen = true
          send   = true
          manage = false
        }
      }
    ]
    subscriptions = [
      {
        name                                 = "recordstopicsubscription"
        max_delivery_count                   = 5
        lock_duration                        = "PT5M" //ISO 8601 format
        forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
        dead_lettering_on_message_expiration = true
        filter_type                          = null
        sql_filter                           = null
        action                               = ""
      }
    ]
  },
  {
    name                         = "legaltags"
    default_message_ttl          = "PT30M" //ISO 8601 format
    enable_partitioning          = false
    requires_duplicate_detection = true
    support_ordering             = true
    authorization_rules = [
      {
        policy_name = "policy"
        claims = {
          listen = true
          send   = true
          manage = false
        }
      }
    ]
    subscriptions = [
      {
        name                                 = "legaltagsubscription"
        max_delivery_count                   = 1
        lock_duration                        = "PT5M" //ISO 8601 format
        forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
        dead_lettering_on_message_expiration = true
        filter_type                          = null
        sql_filter                           = null
        action                               = ""
      },
      {
        name                                 = "compliance-change--integration-test"
        max_delivery_count                   = 1
        lock_duration                        = "PT5M" //ISO 8601 format
        forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
        dead_lettering_on_message_expiration = true
        filter_type                          = null
        sql_filter                           = null
        action                               = ""
      }
    ]
  },
  {
    name                         = "recordstopicdownstream"
    default_message_ttl          = "PT30M" //ISO 8601 format
    enable_partitioning          = false
    requires_duplicate_detection = true
    support_ordering             = true
    authorization_rules = [
      {
        policy_name = "policy"
        claims = {
          listen = true
          send   = true
          manage = false
        }
      }
    ]
    subscriptions = [
      {
        name                                 = "downstreamsub"
        max_delivery_count                   = 1
        lock_duration                        = "PT5M" //ISO 8601 format
        forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
        dead_lettering_on_message_expiration = true
        filter_type                          = null
        sql_filter                           = null
        action                               = ""
      }
    ]
  },
  {
    name                         = "indexing-progress"
    default_message_ttl          = "PT30M" //ISO 8601 format
    enable_partitioning          = false
    requires_duplicate_detection = true
    support_ordering             = true
    authorization_rules = [
      {
        policy_name = "policy"
        claims = {
          listen = true
          send   = true
          manage = false
        }
      }
    ]
    subscriptions = [
      {
        name                                 = "indexing-progresssubscription"
        max_delivery_count                   = 1
        lock_duration                        = "PT5M" //ISO 8601 format
        forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
        dead_lettering_on_message_expiration = true
        filter_type                          = null
        sql_filter                           = null
        action                               = ""
      }
    ]
  }
]

# Database Settings
cosmos_databases = [
  {
    name       = "dev-osdu-r2-db"
    throughput = 400
  }
]

cosmos_sql_collections = [
  {
    name               = "LegalTag"
    database_name      = "dev-osdu-r2-db"
    partition_key_path = "/id"
    throughput         = 400
  },
  {
    name               = "StorageRecord"
    database_name      = "dev-osdu-r2-db"
    partition_key_path = "/id"
    throughput         = 400
  },
  {
    name               = "StorageSchema"
    database_name      = "dev-osdu-r2-db"
    partition_key_path = "/kind"
    throughput         = 400
  },
  {
    name               = "TenantInfo"
    database_name      = "dev-osdu-r2-db"
    partition_key_path = "/id"
    throughput         = 400
  },
  {
    name               = "UserInfo"
    database_name      = "dev-osdu-r2-db"
    partition_key_path = "/id"
    throughput         = 400
  }
]