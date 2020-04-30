resource "azurerm_resource_group" "storage_rg" {
  name     = local.data_rg_name
  location = var.resource_group_location
}

resource "azurerm_management_lock" "data_rg_lock" {
  name       = "osdu_storage_rg_lock"
  scope      = azurerm_resource_group.storage_rg.id
  lock_level = "CanNotDelete"
}

module "storage_account" {
  source = "../../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.storage_rg.name
  container_names     = var.storage_containers
}

module "cache" {
  source              = "../../../../modules/providers/azure/redis-cache"
  name                = local.cache_name
  resource_group_name = azurerm_resource_group.storage_rg.name
}

module "cosmosdb_account" {
  source                   = "../../../../modules/providers/azure/cosmosdb"
  name                     = local.cosmosdb_name
  resource_group_name      = azurerm_resource_group.storage_rg.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = "Session"
  databases                = [local.cosmos_database]
  sql_collections          = local.cosmos_sql_collections
}

resource "azurerm_management_lock" "cosmos_lock" {
  name       = "osdu_storage_cosmos_lock"
  scope      = module.cosmosdb_account.properties.cosmosdb.id
  lock_level = "CanNotDelete"
}

resource "azurerm_management_lock" "storage_acct_lock" {
  name       = "osdu_storage_acct_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}

resource "azurerm_management_lock" "storage_cache_lock" {
  name       = "osdu_storage_cache_lock"
  scope      = module.cache.id
  lock_level = "CanNotDelete"
}
