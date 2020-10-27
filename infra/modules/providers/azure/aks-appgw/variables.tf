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


variable "name" {
  description = "The name of the application gateway."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name that the app gateway will be created in."
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module.  By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "sku_name" {
  description = "The SKU for the Appication Gateway to be created"
  type        = string
  default     = "WAF_v2"
}

variable "tier" {
  description = "The tier of the application gateway. Small/Medium/Large. More details can be found at https://azure.microsoft.com/en-us/pricing/details/application-gateway/"
  type        = string
  default     = "WAF_v2"
}

variable "waf_config_firewall_mode" {
  description = "The firewall mode on the waf gateway"
  type        = string
  default     = "Detection"
}

variable "vnet_name" {
  description = "Virtual Network name that the app gateway will be created in."
  type        = string
}

variable "vnet_subnet_id" {
  description = "Subnet id that the app gateway will be created in."
  type        = string
}

variable "keyvault_id" {
  description = "Key Vault ID holding the ssl certificate used for enabling tls termination."
  type        = string
}

variable "keyvault_secret_id" {
  description = "Key Vault secret ID holding the ssl certificate used for enabling tls termination."
  type        = string
}

variable "ssl_certificate_name" {
  description = "The Name of the SSL certificate that is unique within this Application Gateway"
  type        = string
  default     = "ssl-cert"
}

variable "ssl_policy_type" {
  description = "The Type of the Policy. Possible values are Predefined and Custom."
  type        = string
  default     = "Custom"
}

variable "ssl_policy_cipher_suites" {
  description = "A List of accepted cipher suites."
  type        = list(string)
  default     = ["TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"]
}

variable "ssl_policy_min_protocol_version" {
  description = "The minimal TLS version. Possible values are TLSv1_0, TLSv1_1 and TLSv1_2"
  type        = string
  default     = "TLSv1_2"
}
