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

provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "service-bus" {
    source = "../"

    namespace_name = "osdu-module-service-bus-${module.resource_group.random}"
    resource_group_name = module.resource_group.name
    sku = "Standard"
    namespace_authorization_rules = [{
        claims = {
            listen = "true", 
            send = "true", 
            manage = "false"
        },
        policy_name = "policy"
    }]
    topics = [{
        authorization_rules = [{
            policy_name = "policy", 
            claims = {
                listen = "true", 
                send = "true", 
                manage = "false"
                }
            }], 
        subscriptions = [{
            filter_type = "SqlFilter", 
            sql_filter = "color = 'red'", 
            action = "", 
            name = "sub_test", 
            max_delivery_count = 1, 
            lock_duration = "PT5M", 
            forward_to = "", 
            dead_lettering_on_message_expiration = "true"
        }], 
        name = "topic_test", 
        default_message_ttl = "PT30M", 
        enable_partitioning = "true", 
        requires_duplicate_detection = "true", 
        support_ordering = "true"
    }]
    tags = {
        source = "terraform",
    }
}