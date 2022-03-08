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

# URL to get kubediff which will be installed in the Kubernetes cluster
variable "kubediff_repo_url" {
  type    = string
  default = "https://github.com/weaveworks/kubediff.git"
}

variable "gitops_ssh_url" {
  description = "ssh git clone repository URL with Kubernetes manifests including services which runs in the cluster. Flux monitors this repo for Kubernetes manifest additions/changes preriodiaclly and apply them in the cluster."
  type        = string
}

variable "output_directory" {
  type    = string
  default = "./output"
}

variable "enable_kubediff" {
  type    = string
  default = "false"
}

variable "kubeconfig_filename" {
  description = "Name of the kube config file saved to disk."
  type        = string
  default     = "bedrock_kube_config"
}

variable "kubeconfig_complete" {
  description = "Allows flux to wait for the kubeconfig completion write to disk. Workaround for the fact that modules themselves cannot have dependencies."
  type        = string
}