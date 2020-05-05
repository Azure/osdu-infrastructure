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

module "elastic_cluster" {
  source          = "../../../../modules/providers/elastic/elastic-cloud-enterprise"
  name            = local.elastic_search_name
  coordinator_url = var.ece_endpoint
  auth_type       = var.ece_auth_type
  auth_token      = var.ece_auth_token

  elasticsearch = {
    version = var.elastic_version
    cluster_topology = {
      memory_per_node     = var.elastic_memory_per_node
      node_count_per_zone = var.elastic_nodes_per_zone
      zone_count          = var.elastic_zone_count
      node_type = {
        data   = true
        ingest = true
        master = true
        ml     = false
      }
    }
  }
}