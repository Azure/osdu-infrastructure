provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "service_plan" {
  source              = "../"
  service_plan_name   = "osdu-module-plan-${module.resource_group.random}"
  resource_group_name = module.resource_group.name

  resource_tags = {
    iac = "terraform"
  }
}