provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "storage_account" {
  source              = "../../storage-account"
  resource_group_name = module.resource_group.name
  name                = substr("osdumodule${module.resource_group.random}", 0, 23)
  container_names = [
    "function-releases",
    "private"
  ]
}

module "service_plan" {
  source = "../../service-plan"

  service_plan_name   = "osdu-module-plan-${module.resource_group.random}"
  resource_group_name = module.resource_group.name

  // Container Based Function Apps must be Premium Plan  :-(
  service_plan_tier = "PremiumV2"
  service_plan_size = "P1v2"

  resource_tags = {
    iac = "terraform"
  }
}

module "function_app" {
  source               = "../"
  name                 = "osdu-module-func-${module.resource_group.random}"
  resource_group_name  = module.resource_group.name
  storage_account_name = module.storage_account.name
  service_plan_id      = module.service_plan.app_service_plan_id

  function_app_config = {
    func1 = {
      image = "danielscholl/spring-function-app:latest",
      app_settings = {
        "FUNCTIONS_WORKER_RUNTIME"            = "java"
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = false
      }
    }
  }

  resource_tags = {
    iac = "terraform"
  }
}