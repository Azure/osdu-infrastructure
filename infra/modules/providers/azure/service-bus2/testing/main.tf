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

module "service_bus" {
  source              = "../"
  name                = "osdu-module-service-bus-${module.resource_group.random}"
  resource_group_name = module.resource_group.name
  sku                 = "Standard"

  topics = [
    {
      name                = "topic_test"
      enable_partitioning = true
      subscriptions = [
        {
          name               = "sub_test"
          max_delivery_count = 1
          lock_duration      = "PT5M"
          forward_to         = ""
        }
      ]
    }
  ]

  resource_tags = {
    source = "terraform",
  }
}
