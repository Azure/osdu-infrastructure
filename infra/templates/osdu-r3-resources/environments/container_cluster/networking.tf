module "vnet" {
  source = "github.com/microsoft/bedrock?ref=master//cluster/azure/vnet"

  vnet_name           = local.vnet_name
  address_space       = var.address_space
  resource_group_name = azurerm_resource_group.aks_rg.name
  subnet_names        = [local.aks_subnet_name]
  subnet_prefixes     = [var.subnet_prefix]

  tags = {
    environment = "container_cluster"
  }
}
