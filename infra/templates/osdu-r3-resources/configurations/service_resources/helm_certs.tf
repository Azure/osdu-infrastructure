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
  helm_certs_name    = "jetstack"
  helm_certs_ns      = "cert-manager"
  helm_certs_repo    = "https://charts.jetstack.io"
  helm_certs_version = "v0.16.1"
}

resource "kubernetes_namespace" "certs" {
  metadata {
    name = local.helm_certs_ns
    labels = {
      "cert-manager.io/disable-validation" = "true"
    }
  }

  depends_on = [module.aks-gitops]
}

resource "helm_release" "certmgr" {
  name       = local.helm_certs_name
  repository = local.helm_certs_repo
  chart      = "cert-manager"
  version    = local.helm_certs_version
  namespace  = local.helm_certs_ns
  depends_on = [kubernetes_namespace.certs]

  set {
    name  = "installCRDs"
    value = true
  }
}
