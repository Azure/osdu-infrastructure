provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "cosmosdb" {
  source = "../"

  name                = "osdu-module-db-${module.resource_group.random}"
  resource_group_name = module.resource_group.name

  kind                     = "GlobalDocumentDB"
  automatic_failover       = false
  consistency_level        = "Session"
  primary_replica_location = module.resource_group.location
  databases = [
    {
      name       = "osdu-module-database1"
      throughput = 400
    },
    {
      name       = "osdu-module-database2"
      throughput = 400
    }
  ]
  sql_collections = [
    {
      name               = "osdu-module-container1"
      database_name      = "osdu-module-database1"
      partition_key_path = "/id"
      throughput         = 400
    },
    {
      name               = "osdu-module-container2"
      database_name      = "osdu-module-database1"
      partition_key_path = "/id"
      throughput         = 400
    },
    {
      name               = "osdu-module-container1"
      database_name      = "osdu-module-database2"
      partition_key_path = "/id"
      throughput         = 400
    },
    {
      name               = "osdu-module-container2"
      database_name      = "osdu-module-database2"
      partition_key_path = "/id"
      throughput         = 400
    }
  ]

  tags = {
    source = "terraform",
  }
}
