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


// *** THIS MODULE DOESN"T SUPPORT 2.0 PROVIDER ***
provider "azurerm" {
  version = "~>1.40.0"
}

module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "service_plan" {
  source = "../../service-plan"

  service_plan_name   = "osdu-module-plan-${module.resource_group.random}"
  resource_group_name = module.resource_group.name
}

module "app_service" {
  source = "../"

  app_service_name_prefix          = "iac-terraform-web-${module.resource_group.random}"
  service_plan_resource_group_name = module.resource_group.name

  service_plan_name                = module.service_plan.service_plan_name
  docker_registry_server_url       = "mcr.microsoft.com"
  app_insights_instrumentation_key = "secret_key"

  app_service_settings = {
    iac = "terraform"
  }

  app_service_config = {
    web1 = {
      image            = "azuredocs/aci-helloworld:latest"
      app_command_line = null
      linux_fx_version = "JAVA|8-jre8"
      app_settings = {
        tf_setting = "setting1"
      }
    }
  }

  vnet_name = "test"

  resource_tags = {
    source = "terraform",
  }
}