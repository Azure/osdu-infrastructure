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
