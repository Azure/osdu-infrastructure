locals {
  throughput = 400
  cosmos_database = {
    name       = local.cosmos_db_name
    throughput = local.throughput
  }

  cosmos_sql_collections = [
    {
      name               = "LegalTag"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "StorageRecord"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "StorageSchema"
      database_name      = local.cosmos_db_name
      partition_key_path = "/kind"
      throughput         = local.throughput
    },
    {
      name               = "TenantInfo"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    },
    {
      name               = "UserInfo"
      database_name      = local.cosmos_db_name
      partition_key_path = "/id"
      throughput         = local.throughput
    }
  ]
}

module "storage_account" {
  source = "../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.app_rg.name
  container_names     = var.storage_containers
}

module "function_storage" {
  source = "../../modules/providers/azure/storage-account"

  name                = local.function_storage_name
  resource_group_name = azurerm_resource_group.app_rg.name
  container_names     = []
}

module "cache" {
  source              = "../../modules/providers/azure/redis-cache"
  name                = local.cache_name
  resource_group_name = azurerm_resource_group.app_rg.name
}

module "cosmosdb_account" {
  source                   = "../../modules/providers/azure/cosmosdb"
  name                     = local.cosmosdb_name
  resource_group_name      = azurerm_resource_group.app_rg.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = "Session"
  databases                = [local.cosmos_database]
  sql_collections          = local.cosmos_sql_collections
}
