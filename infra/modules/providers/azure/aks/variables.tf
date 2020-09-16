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
  description = "The name of the Kubernetes Cluster."
  type        = string
}

variable "resource_group_name" {
  description = "The name of an existing resource group."
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "dns_prefix" {
  type = string
}

variable "agent_vm_count" {
  type    = string
  default = "2"
}

variable "max_node_count" {
  type    = string
  default = "10"
}

variable "agent_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "max_pods" {
  type    = string
  default = 30
}

variable "kubernetes_version" {
  type    = string
  default = "1.17.9"
}

variable "admin_user" {
  type    = string
  default = "k8sadmin"
}

variable "ssh_public_key" {
  type = string
}

variable "output_directory" {
  type    = string
  default = "./output"
}

variable "vnet_subnet_id" {
  type = string
}

variable "enable_virtual_node_addon" {
  type    = string
  default = "false"
}

variable "kubeconfig_to_disk" {
  description = "This disables or enables the kube config file from being written to disk."
  type        = string
  default     = "true"
}

variable "kubeconfig_filename" {
  description = "Name of the kube config file saved to disk."
  type        = string
  default     = "bedrock_kube_config"
}

variable "service_cidr" {
  default     = "10.0.0.0/16"
  description = "Used to assign internal services in the AKS cluster an IP address. This IP address range should be an address space that isn't in use elsewhere in your network environment. This includes any on-premises network ranges if you connect, or plan to connect, your Azure virtual networks using Express Route or a Site-to-Site VPN connections."
  type        = string
}

variable "dns_ip" {
  default     = "10.0.0.10"
  description = "should be the .10 address of your service IP address range"
  type        = string
}

variable "docker_cidr" {
  default     = "172.17.0.1/16"
  description = "IP address (in CIDR notation) used as the Docker bridge IP address on nodes. Default of 172.17.0.1/16."
}

variable "network_plugin" {
  default     = "azure"
  description = "Network plugin used by AKS. Either azure or kubenet."
}

variable "network_policy" {
  default     = "azure"
  description = "Network policy to be used with Azure CNI. Either azure or calico."
}

variable "auto_scaling_default_node" {
  description = "(Optional) Kubernetes Auto Scaler must be enabled for this main pool"
  type        = bool
  default     = false
}

variable "oms_agent_enabled" {
  default     = "false"
  description = "Enable Azure Monitoring for AKS"
  type        = string
}

variable "log_analytics_id" {
  description = "Id of the log analytics workspace"
  type        = string
  default     = ""
}

variable "service_principal_id" {
  type    = string
  default = ""
}

variable "service_principal_secret" {
  type    = string
  default = ""
}

variable "msi_enabled" {
  type    = bool
  default = true
}

variable "enable_kube_dashboard" {
  type    = bool
  default = true
}