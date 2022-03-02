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


module "network" {
  source = "../"

  name                = "osdu-module-vnet-${module.resource_group.random}"
  resource_group_name = module.resource_group.name
  address_space       = "10.0.1.0/24"
  dns_servers         = ["8.8.8.8"]
  subnet_prefixes     = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26", "10.0.1.192/27", "10.0.1.224/28"]
  subnet_names        = ["Web-Tier", "App-Tier", "Data-Tier", "Mgmt-Tier", "GatewaySubnet"]

  # Tags
  resource_tags = {
    osdu = "module"
  }

}