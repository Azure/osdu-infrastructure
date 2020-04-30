variable "resource_group_location" {
  description = "The Azure region where data storage resources in this template should be created."
  type        = string
}

variable "storage_containers" {
  description = "The list of storage container names to create. Names must be unique per storage account."
  type        = list(string)
}

###
# Begin: Cosmos configuration
###
variable "cosmos_db_name" {
  description = "(Required) The name that CosmosDB will be created with."
  type        = string
}

variable "cosmosdb_replica_location" {
  description = "The name of the Azure region to host replicated data. i.e. 'East US' 'East US 2'. More locations can be found at https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  type        = string
}

variable "cosmosdb_automatic_failover" {
  description = "Determines if automatic failover is enabled for CosmosDB."
  type        = bool
  default     = true
}
###
# End: Cosmos configuration
###

###
# Begin: Elasticsearch configuration
###
variable "ece_endpoint" {
  description = "(Required) Determines the ECE endpoint to target for deploying ELK stack resources"
  type        = string
}

variable "ece_auth_token" {
  description = "(Required) Determines the authentication token used for authenticating with ECE"
  type        = string
}

variable "ece_auth_type" {
  description = "Determinds the authentication type for authenticating with ECE"
  type        = string
  default     = "Basic"
}

variable "elastic_version" {
  description = "Determines the version of Elasticsearch to provision"
  type        = string
  default     = "6.8.3"
}

variable "elastic_memory_per_node" {
  description = "Determines how many MB of memory are allocated to each Elasticsearch node"
  type        = number
  default     = 1024
}

variable "elastic_nodes_per_zone" {
  description = "Determines how many nodes the Elasticsearch deployment provision in each zone"
  type        = number
  default     = 1
}

variable "elastic_zone_count" {
  description = "Determines how many zones the Elasticsearch deployment will provision into"
  type        = number
  default     = 1
}
###
# End: Elasticsearch configuration
###
