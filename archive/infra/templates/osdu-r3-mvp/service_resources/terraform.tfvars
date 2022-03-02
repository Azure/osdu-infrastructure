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

/*
.Synopsis
   Terraform Variable Configuration
.DESCRIPTION
   This file holds the Default Variable Configuration
*/

prefix = "osdu-mvp"

resource_tags = {
  contact = "pipeline"
}

# Kubernetes Settings
kubernetes_version = "1.18.8"
aks_agent_vm_size  = "Standard_E4s_v3"
aks_agent_vm_count = "5"
subnet_aks_prefix  = "10.10.2.0/23"

# Storage Settings
storage_replication_type = "LRS"
storage_containers = [
  "azure-webjobs-hosts",
  "airflow-logs"
]
storage_shares = [
  "airflowdags",
  "unit",
  "crs"
]
storage_queues = [
  "airflowlogqueue"
]
