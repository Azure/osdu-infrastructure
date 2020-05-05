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
  }
]
