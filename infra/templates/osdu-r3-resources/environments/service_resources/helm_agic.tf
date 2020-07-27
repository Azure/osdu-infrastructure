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
  helm_agic_name   = "agic"
  helm_agic_ns     = "agic"
  helm_agic_repo   = "https://blobbloghelmagic.blob.core.windows.net/helm"
  helm_agic_version = "1.0.0"
}


/*START AGIC role assignments*/
resource "azurerm_role_assignment" "operator" {
  principal_id         = module.aks-gitops.kubelet_client_id
  scope                = module.appgateway.managed_identity_resource_id
  role_definition_name = "Managed Identity Operator"
}
/*END AGIC-specific role assignments*/


resource "kubernetes_namespace" "agic" {
  metadata {
    name = local.helm_agic_ns
  }
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
    value = module.appgateway.managed_identity_resource_id
  }

  set {
    name  = "armAuth.identityClientID"
    value = module.appgateway.managed_identity_principal_id
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
}