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


#-------------------------------
# Keda
#-------------------------------
locals {
  helm_keda_name    = "keda"
  helm_keda_ns      = "keda"
  helm_keda_repo    = "https://kedacore.github.io/charts"
  helm_keda_version = "1.4"
}

resource "kubernetes_namespace" "keda" {
  metadata {
    name = local.helm_keda_ns
  }

  depends_on = [module.aks]
}

resource "helm_release" "keda" {
  name       = local.helm_keda_name
  repository = local.helm_keda_repo
  chart      = "keda"
  version    = local.helm_keda_version
  namespace  = local.helm_keda_ns

  depends_on = [kubernetes_namespace.keda]
}