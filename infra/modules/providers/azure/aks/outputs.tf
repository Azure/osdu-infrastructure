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

output "principal_id" {
  value = azurerm_kubernetes_cluster.main.identity.0.principal_id
}

output "kubelet_identity_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity.0.user_assigned_identity_id
}

output "kubelet_object_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
}

output "kubelet_client_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity.0.client_id
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.main.node_resource_group
}