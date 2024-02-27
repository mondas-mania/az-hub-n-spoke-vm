module "internal_vnet" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"

  resource_group_name = data.azurerm_resource_group.resource_group.name
  vnet_location       = data.azurerm_resource_group.resource_group.location
  use_for_each        = true

  vnet_name       = "internal-vnet"
  address_space   = [var.internal_cidr_range]
  subnet_names    = local.internal_subnet_names
  subnet_prefixes = local.internal_subnet_prefixes
}