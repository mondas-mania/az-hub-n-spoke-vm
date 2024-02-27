module "hub_vnet" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"

  resource_group_name = data.azurerm_resource_group.resource_group.name
  vnet_location       = data.azurerm_resource_group.resource_group.location
  use_for_each        = true

  vnet_name       = "hub-vnet"
  address_space   = [var.hub_cidr_range]
  subnet_names    = ["hub-subnet-0"]
  subnet_prefixes = [var.hub_cidr_range]
}
