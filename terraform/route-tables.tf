#########################
# Spoke to Hub Supernet #
#########################

resource "azurerm_route_table" "spoke_to_hub" {
  for_each                      = var.internal_vnets_config
  name                          = "${each.key}-route-table"
  location                      = data.azurerm_resource_group.resource_group.location
  resource_group_name           = data.azurerm_resource_group.resource_group.name
  disable_bgp_route_propagation = true
}

##########
# Routes #
##########

resource "azurerm_route" "spoke_to_hub" {
  for_each               = var.enable_router_vm ? var.internal_vnets_config : {}
  name                   = "to_hub"
  resource_group_name    = data.azurerm_resource_group.resource_group.name
  route_table_name       = azurerm_route_table.spoke_to_hub[each.key].name
  address_prefix         = var.supernet_cidr_range
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.router_ubuntu_nic_private[0].private_ip_address
}

resource "azurerm_route" "spoke_to_local" {
  for_each            = var.internal_vnets_config
  name                = "to_local"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  route_table_name    = azurerm_route_table.spoke_to_hub[each.key].name
  address_prefix      = each.value.cidr_range
  next_hop_type       = "VnetLocal"
}

# add nat_gw route
locals {
  central_nat_gw_routes = { for vnet_name, vnet_config in var.internal_vnets_config : vnet_name => {
    name                = "to_central_nat_gw"
    next_hop_type       = "VirtualAppliance"
    next_hop_ip_address = azurerm_network_interface.router_ubuntu_nic_private[0].private_ip_address
    } if(vnet_config.enable_nat_gw == false && var.enable_router_vm)
  }

  local_nat_gw_routes = { for vnet_name, vnet_config in var.internal_vnets_config : vnet_name => {
    name                = "to_local_nat_gw"
    next_hop_type       = "Internet"
    next_hop_ip_address = null
    } if vnet_config.enable_nat_gw
  }

  nat_gw_routes = merge(local.central_nat_gw_routes, local.local_nat_gw_routes)
}

resource "azurerm_route" "spoke_to_natgw" {
  for_each               = local.nat_gw_routes
  name                   = each.value.name
  resource_group_name    = data.azurerm_resource_group.resource_group.name
  route_table_name       = azurerm_route_table.spoke_to_hub[each.key].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_ip_address
}


#######################
# Subnet Associations #
#######################

locals {
  subnet_rtbs = merge([
    for vnet_name, vnet_config in local.subnets_config : {
      for subnet_name, subnet_config in vnet_config.subnets : "${vnet_name}/${subnet_name}" => {
        "subnet_id" = module.spoke_vnet[vnet_name].vnet_subnets_name_id[subnet_name]
        "rtb_id"    = azurerm_route_table.spoke_to_hub[vnet_name].id
      } if subnet_name != "AzureBastionSubnet"
    }
  ]...)
}

resource "azurerm_subnet_route_table_association" "spoke_rtb_assoc" {
  for_each       = local.subnet_rtbs
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.rtb_id
}