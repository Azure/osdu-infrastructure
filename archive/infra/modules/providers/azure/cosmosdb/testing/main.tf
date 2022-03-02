provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}


module "cosmosdb_autoscale" {
  source = "../"

  name                = "osdu-module-db2-${module.resource_group.random}"
  resource_group_name = module.resource_group.name

  kind                     = "GlobalDocumentDB"
  automatic_failover       = true
  consistency_level        = "Session"
  primary_replica_location = module.resource_group.location

  databases = [
    {
      name       = "osdu-module-database"
      throughput = 4000 # This is max throughput Minimum level is 4000
    }
  ]
  sql_collections = [
    {
      name               = "osdu-module-container1"
      database_name      = "osdu-module-database"
      partition_key_path = "/id"

    },
    {
      name               = "osdu-module-container2"
      database_name      = "osdu-module-database"
      partition_key_path = "/id"
    }
  ]

  resource_tags = {
    source = "terraform",
  }
}