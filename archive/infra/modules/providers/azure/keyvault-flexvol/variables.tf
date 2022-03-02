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

variable "resource_group_name" {
  type = string
}

variable "service_principal_id" {
  type = string
}

variable "service_principal_secret" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "flexvol_keyvault_key_permissions" {
  description = "Permissions that the AKS cluster has for accessing keys from KeyVault"
  type        = list
  default     = ["create", "delete", "get"]
}

variable "flexvol_keyvault_secret_permissions" {
  description = "Permissions that the AKS cluster has for accessing secrets from KeyVault"
  type        = list
  default     = ["set", "delete", "get"]
}

variable "flexvol_keyvault_certificate_permissions" {
  description = "Permissions that the AKS cluster has for accessing certificates from KeyVault"
  type        = list
  default     = ["create", "delete", "get"]
}

variable "flexvol_deployment_url" {
  description = "The url to the yaml file for deploying the KeyVault flex volume."
  type        = string
  default     = "https://raw.githubusercontent.com/Azure/kubernetes-keyvault-flexvol/31f593250045e8dc861e13a8e943284787b7f17e/deployment/kv-flexvol-installer.yaml"
}

variable "output_directory" {
  type    = string
  default = "./output"
}

variable "enable_flexvol" {
  type    = string
  default = "true"
}

variable "keyvault_name" {
  description = "The name of the keyvault that will be associated with the flex volume."
  type        = string
}

variable "flexvol_recreate" {
  description = "Make any change to this value to trigger the recreation of the flex volume execution script."
  type        = string
  default     = ""
}

variable "kubeconfig_filename" {
  description = "Name of the kube config file saved to disk."
  type        = string
  default     = "bedrock_kube_config"
}

variable "kubeconfig_complete" {
  description = "Allows flex volume deployment to wait for the kubeconfig completion write to disk. Workaround for the fact that modules themselves cannot have dependencies."
  type        = string
}