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

output "id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "client_certificate" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
}

output "kube_config" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
}

output "kube_config_block" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.main.kube_config
}

output "kubeconfig_done" {
  value = join("", local_file.cluster_credentials.*.id)
}

output "node_resource_group" {
  value = data.external.az_cli.result.node_resource_group
}

output "msi_client_id" {
  value = data.external.az_cli.result.user_assigned_identity_id
}

# output "kubelet_client_id" {
#   value = azurerm_kubernetes_cluster.main.kubelet_identity.client_id
# }

# output "kubelet_id" {
#   value = azurerm_kubernetes_cluster.main.kubelet_identity.object_id
# }

# output "kubelet_resource_id" {
#   value = data.external.msi_object_id.result.kubelet_resource_id
# }