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

provider "azurerm" {
  features {}
}

module "resource_group" {
  source   = "../../resource-group"
  name     = "osdu-module"
  location = "eastus2"
}

module "network" {
  source = "../../network"

  name                = format("osdu-module-vnet-%s", module.resource_group.random)
  resource_group_name = module.resource_group.name
  address_space       = "10.10.0.0/16"
  dns_servers         = ["8.8.8.8"]
  subnet_prefixes     = ["10.10.1.0/24"]
  subnet_names        = ["Cluster-Subnet"]
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "null_resource" "save-key" {
  triggers = {
    key = tls_private_key.key.private_key_pem
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.key.private_key_pem}" > ${path.module}/.ssh/id_rsa
      chmod 0600 ${path.module}/.ssh/id_rsa
    EOF
  }
}

data "azurerm_client_config" "current" {}

module "aks" {
  source = "../"

  name                = format("osdu-module-cluster-%s", module.resource_group.random)
  resource_group_name = module.resource_group.name
  dns_prefix          = format("osdu-module-cluster-%s", module.resource_group.random)
  ssh_public_key      = "${trimspace(tls_private_key.key.public_key_openssh)} k8sadmin"
  vnet_subnet_id      = module.network.subnets.0

  msi_enabled           = true
  kubeconfig_to_disk    = false
  oms_agent_enabled     = true
  enable_kube_dashboard = false

  resource_tags = {
    osdu = "module"
  }
}