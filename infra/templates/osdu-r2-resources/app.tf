// This file contains all of the resources that exist within the app dev subscription. Design documentation
// with more information on exactly what resources live here can be found at ./docs/README.md

resource "azurerm_resource_group" "app_rg" {
  name     = local.app_rg_name
  location = local.region
}

locals {
  aad_reply_uris = flatten([
    for config in module.authn_app_service.app_service_config_data :
    [
      format("https://%s", config.app_fqdn),
      format("https://%s/.auth/login/aad/callback", config.app_fqdn),
      format("https://%s", config.slot_fqdn),
      format("https://%s/.auth/login/aad/callback", config.slot_fqdn),
      format("http://localhost:8080"),
      format("http://locahost:8080/auth/callback")
    ]
  ])
}

// ### See Issue "841: Re-enable Resource Group Locking, prior to cobalt template being released"
//resource "azurerm_management_lock" "app_rg_lock" {
//  name       = local.app_rg_lock
//  scope      = azurerm_resource_group.app_rg.id
//  lock_level = "CanNotDelete"
//
//  lifecycle {
//    prevent_destroy = true
//  }
//}

module "app_insights" {
  source                           = "../../modules/providers/azure/app-insights"
  service_plan_resource_group_name = azurerm_resource_group.app_rg.name
  appinsights_name                 = local.ai_name
  appinsights_application_type     = "Web"
}

module "service_plan" {
  source              = "../../modules/providers/azure/service-plan"
  resource_group_name = azurerm_resource_group.app_rg.name
  service_plan_name   = local.sp_name
  scaling_rules       = var.scaling_rules
  service_plan_size   = var.service_plan_size
  service_plan_tier   = var.service_plan_tier
}

module "authn_app_service" {
  source                           = "../../modules/providers/azure/app-service"
  service_plan_name                = module.service_plan.service_plan_name
  app_service_name_prefix          = local.auth_svc_name_prefix
  app_service_settings             = merge(var.app_service_settings, local.app_service_global_config)
  service_plan_resource_group_name = azurerm_resource_group.app_rg.name
  app_insights_instrumentation_key = module.app_insights.app_insights_instrumentation_key
  vault_uri                        = module.keyvault.keyvault_uri
  app_service_config = {
    for target in var.app_services :
    target.app_name => {
      image            = target.image
      app_command_line = target.app_command_line
      linux_fx_version = target.linux_fx_version
      app_settings     = target.app_settings
    }
  }
}

module "ad_application" {
  source               = "../../modules/providers/azure/ad-application"
  resource_access_type = "Scope"
  ad_app_config = [
    {
      app_name   = local.ad_app_name
      reply_urls = []
    }
  ]
  resource_app_id  = local.graph_id
  resource_role_id = local.graph_role_id
}

resource "null_resource" "auth" {
  /* Orchestrates the destroy and create process of null_resource.auth dependencies
  /  during subsequent deployments that require new resources.
  */
  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    app_service = join(",", module.authn_app_service.app_service_uris)
  }
  provisioner "local-exec" {
    command = <<EOF
      az ad app update           \
        --id "$APP_ID"           \
        --reply-urls $REPLY_URLS \
      EOF

    environment = {
      REPLY_URLS = join(" ", local.aad_reply_uris)
      APP_ID     = module.ad_application.azuread_config_data[local.ad_app_name].application_id
    }
  }
}

## Service Bus
module "service_bus" {
  source              = "../../modules/providers/azure/service-bus"
  namespace_name      = local.sb_namespace
  resource_group_name = azurerm_resource_group.app_rg.name
  sku                 = var.sb_sku
  topics              = var.sb_topics
}

module "container_registry" {
  source = "../../modules/providers/azure/container-registry"

  container_registry_name = local.acr_name
  resource_group_name     = azurerm_resource_group.app_rg.name

  container_registry_sku           = var.container_registry_sku
  container_registry_admin_enabled = false
}

module "function_app" {
  source = "../../modules/providers/azure/function-app"

  name                = local.functionapp_name
  resource_group_name = azurerm_resource_group.app_rg.name

  storage_account_name = module.function_storage.name
  service_plan_id      = module.service_plan.app_service_plan_id
  instrumentation_key  = module.app_insights.app_insights_instrumentation_key

  docker_registry_server_url      = module.container_registry.container_registry_login_server
  docker_registry_server_username = format(local.app_setting_kv_format, local.output_secret_map.app-dev-sp-username)
  docker_registry_server_password = format(local.app_setting_kv_format, local.output_secret_map.app-dev-sp-password)

  function_app_config = {
    for target in var.function_apps :
    target.function_name => {
      app_settings = merge(local.function_app_global_config, target.app_settings)
      image        = lookup(target, "image", "") // Image Deployment will always come post terraform deploy for the template
    }
  }
}
