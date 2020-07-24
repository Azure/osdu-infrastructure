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

resource "null_resource" "deploy_flux" {
  count = var.enable_flux ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Need to use this var so terraform waits for kubeconfig ' ${var.kubeconfig_complete};KUBECONFIG=${var.output_directory}/${var.kubeconfig_filename} ${path.module}/deploy_flux.sh -b '${var.gitops_url_branch}' -f '${var.flux_repo_url}' -g '${var.gitops_ssh_url}' -k '${var.gitops_ssh_key_path}' -d '${var.flux_clone_dir}' -c '${var.gitops_poll_interval}' -l '${var.gitops_label}' -e '${var.gitops_path}' -s '${var.acr_enabled}' -r '${var.flux_image_repository}' -t '${var.flux_image_tag}' -z '${var.gc_enabled}'"
  }

  triggers = {
    enable_flux   = var.enable_flux
    flux_recreate = var.flux_recreate
  }
}