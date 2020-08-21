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

locals {
  helm_kv_csi_name    = "kvsecrets"
  helm_kv_csi_ns      = "kvsecrets"
  helm_kv_csi_repo    = "https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
  helm_kv_csi_version = "0.0.9"
}

resource "kubernetes_namespace" "kvsecrets" {
  metadata {
    name = local.helm_kv_csi_ns
  }

  depends_on = [module.aks-gitops]
}

resource "helm_release" "kvsecrets" {
  name       = local.helm_kv_csi_name
  repository = local.helm_kv_csi_repo
  chart      = "csi-secrets-store-provider-azure"
  version    = local.helm_kv_csi_version
  namespace  = local.helm_kv_csi_ns

  set {
    name  = "secrets-store-csi-driver.linux.metricsAddr"
    value = ":8081"
  }

  depends_on = [kubernetes_namespace.kvsecrets]
}