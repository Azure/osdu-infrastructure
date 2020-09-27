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


data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

locals {
  public_ip_name                 = format("%s-ip", var.name)
  gateway_ip_configuration_name  = format("%s-config", var.vnet_name)
  backend_address_pool_name      = format("%s-beap", var.vnet_name)
  frontend_port_name             = format("%s-feport", var.vnet_name)
  frontend_ip_configuration_name = format("%s-feip", var.vnet_name)
  backend_http_settings          = format("%s-be-htst", var.vnet_name)
  listener_name                  = format("%s-httplstn", var.vnet_name)
  request_routing_rule_name      = format("%s-rqrt", var.vnet_name)
  identity_name                  = format("%s-identity", var.name)
}

resource "azurerm_public_ip" "main" {
  name                = local.public_ip_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  allocation_method = "Static"
  sku               = "Standard"
  domain_name_label = var.name

  tags = var.resource_tags
}

// This Identity is used for accessing Key Vault to retrieve SSL Certificate
resource "azurerm_user_assigned_identity" "main" {
  name                = local.identity_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  tags = var.resource_tags
}


module "app_gw_keyvault_access_policy" {
  source    = "../keyvault-policy"
  vault_id  = var.keyvault_id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_ids = [
    azurerm_user_assigned_identity.main.principal_id
  ]
  key_permissions         = []
  secret_permissions      = ["get"]
  certificate_permissions = ["get"]
}


## Reference Configuration:  https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview
resource "azurerm_application_gateway" "main" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = var.resource_tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  waf_configuration {
    enabled          = var.tier == "WAF" || var.tier == "WAF_v2" ? true : false
    firewall_mode    = var.waf_config_firewall_mode
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"
  }

  identity {
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  autoscale_configuration {
    min_capacity = 2
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = var.vnet_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.main.id
  }

  ########
  ### Listener 1 http://mygateway.com
  ########

  http_listener {
    name                           = format("http-%s", local.listener_name)
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = format("http-%s", local.frontend_port_name)
    protocol                       = "Http"
  }

  frontend_port {
    name = format("http-%s", local.frontend_port_name)
    port = 80
  }

  request_routing_rule {
    name                       = format("http-%s", local.request_routing_rule_name)
    rule_type                  = "Basic"
    http_listener_name         = format("http-%s", local.listener_name)
    backend_address_pool_name  = format("http-%s", local.backend_address_pool_name)
    backend_http_settings_name = format("http-%s", local.backend_http_settings)
  }

  backend_http_settings {
    name                  = format("http-%s", local.backend_http_settings)
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_address_pool {
    name = format("http-%s", local.backend_address_pool_name)
  }

  ########
  ### Listener 2 https://mygateway.com
  ########

  http_listener {
    name                           = format("https-%s", local.listener_name)
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = format("https-%s", local.frontend_port_name)
    protocol                       = "Https"
    ssl_certificate_name           = var.ssl_certificate_name
  }

  frontend_port {
    name = format("https-%s", local.frontend_port_name)
    port = 443
  }

  ssl_certificate {
    name                = var.ssl_certificate_name
    key_vault_secret_id = var.keyvault_secret_id
  }

  request_routing_rule {
    name                       = format("https-%s", local.request_routing_rule_name)
    rule_type                  = "Basic"
    http_listener_name         = format("https-%s", local.listener_name)
    backend_address_pool_name  = format("https-%s", local.backend_address_pool_name)
    backend_http_settings_name = format("https-%s", local.backend_http_settings)
  }

  backend_http_settings {
    name                  = format("https-%s", local.backend_http_settings)
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 1
  }

  backend_address_pool {
    name = format("https-%s", local.backend_address_pool_name)
  }

  lifecycle {
    ignore_changes = [
      ssl_certificate,
      request_routing_rule,
      http_listener,
      backend_http_settings,
      backend_address_pool,
      probe,
      tags,
      frontend_port,
      redirect_configuration,
      url_path_map
    ]
  }
}