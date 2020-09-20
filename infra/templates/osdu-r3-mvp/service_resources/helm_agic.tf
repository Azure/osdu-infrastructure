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
# Application Gateway Ingress Controller
#-------------------------------
locals {
  helm_agic_name    = "agic"
  helm_agic_ns      = "agic"
  helm_agic_repo    = "https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/"
  helm_agic_version = "1.2.0"
}


resource "kubernetes_namespace" "agic" {
  metadata {
    name = local.helm_agic_ns
  }

  depends_on = [module.aks]
}

resource "helm_release" "agic" {
  name       = local.helm_agic_name
  repository = local.helm_agic_repo
  chart      = "ingress-azure"
  version    = local.helm_agic_version
  namespace  = kubernetes_namespace.agic.metadata.0.name


  set {
    name  = "appgw.subscriptionId"
    value = data.azurerm_client_config.current.subscription_id
  }

  set {
    name  = "appgw.resourceGroup"
    value = azurerm_resource_group.main.name
  }

  set {
    name  = "appgw.name"
    value = module.appgateway.name
  }

  set {
    name  = "armAuth.identityResourceID"
    value = azurerm_user_assigned_identity.agicidentity.id
  }

  set {
    name  = "armAuth.identityClientID"
    value = azurerm_user_assigned_identity.agicidentity.client_id
  }

  set {
    name  = "armAuth.type"
    value = "aadPodIdentity"
  }

  set {
    name  = "appgw.shared"
    value = false
  }

  set {
    name  = "appgw.usePrivateIP"
    value = false
  }

  set {
    name  = "rbac.enabled"
    value = true
  }

  set {
    name  = "verbosityLevel"
    value = 5
  }

  depends_on = [helm_release.aad_pod_id]
}
