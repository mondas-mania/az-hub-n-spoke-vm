locals {
  spoke_nat_gws = {
    for vnet_name, vnet_config in var.internal_vnets_config : vnet_name => {
      for subnet_name, subnet_id in module.spoke_vnet[vnet_name].vnet_subnets_name_id : subnet_name => subnet_id if subnet_name != "AzureBastionSubnet"
    } if vnet_config.enable_nat_gw
  }

  central_nat_gw = var.enable_central_nat_gateway ? {
    "hub-vnet" = { for subnet_name, subnet_id in module.hub_vnet.vnet_subnets_name_id : subnet_name => subnet_id if subnet_name != "AzureBastionSubnet" }
  } : {}

  nat_gws = merge(local.spoke_nat_gws, local.central_nat_gw)

  nat_gws_flattened = merge(
    [for vnet_name, subnets in local.nat_gws : { for subnet_name, subnet_id in subnets : "${vnet_name}/${subnet_name}" => { vnet_name = vnet_name, subnet_name = subnet_name, subnet_id = subnet_id } }]...
  )
}

resource "azurerm_nat_gateway" "nat_gw" {
  for_each                = local.nat_gws
  name                    = "nat-gateway-${each.key}"
  location                = data.azurerm_resource_group.resource_group.location
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  zones                   = []
}

resource "azurerm_public_ip" "nat_gw_pip" {
  for_each            = local.nat_gws
  name                = "nat-gw-pip-${each.key}"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_pip_association" {
  for_each             = local.nat_gws
  nat_gateway_id       = azurerm_nat_gateway.nat_gw[each.key].id
  public_ip_address_id = azurerm_public_ip.nat_gw_pip[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "nat_gw_subnet_association" {
  for_each       = local.nat_gws_flattened
  subnet_id      = each.value.subnet_id
  nat_gateway_id = azurerm_nat_gateway.nat_gw[each.value.vnet_name].id
}
