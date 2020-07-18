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

#!/bin/sh

# parse command-line arguments
while getopts :i:p:u: option 
do 
 case "${option}" in 
 i) SERVICE_PRINCIPAL_ID=${OPTARG};;
 p) SERVICE_PRINCIPAL_SECRET=${OPTARG};;
 u) FLEXVOL_DEPLOYMENT_URL=${OPTARG};;
 *) echo "ERROR: Please refer to usage guide on GitHub" >&2
    exit 1 ;;
 esac
done 

# Deploy the flex volume support into the cluster
if ! kubectl create -f "$FLEXVOL_DEPLOYMENT_URL"
then
    echo "Unable to deploy flex volume support to cluster."
    exit 1
fi

echo "Adding service principal into KeyVault as a secret"

if ! kubectl create secret generic kvcreds --from-literal clientid="$SERVICE_PRINCIPAL_ID" --from-literal clientsecret="$SERVICE_PRINCIPAL_SECRET" --type=azure/kv
then
    echo "Unable to add service principal secrets to kubectl secret"
    exit 1
fi