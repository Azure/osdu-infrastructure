#  Copyright © Microsoft Corporation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/usr/bin/env bash
set -euo pipefail

az aks show -n $1 -g $2 --subscription $3 -ojson --query "{kubelet_client_id:identityProfile.kubeletidentity.objectId,msi_client_id:identity.principalId,kubelet_id:identityProfile.kubeletidentity.resourceId,kubelet_resource_id:identityProfile.kubeletidentity.resourceId,node_resource_group:nodeResourceGroup}"
