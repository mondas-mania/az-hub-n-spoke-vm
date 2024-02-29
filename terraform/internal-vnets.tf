module "spoke_vnet" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"

  for_each = local.subnets_config

  resource_group_name = data.azurerm_resource_group.resource_group.name
  vnet_location       = data.azurerm_resource_group.resource_group.location
  use_for_each        = true

  vnet_name       = each.key
  address_space   = [each.value.cidr_range]
  subnet_names    = [for name, prefix in each.value.subnets : name]
  subnet_prefixes = [for name, prefix in each.value.subnets : prefix]
}
