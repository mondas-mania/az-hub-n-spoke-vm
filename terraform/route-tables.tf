#########################
# Spoke to Hub Supernet #
#########################

resource "azurerm_route_table" "spoke_to_hub" {
  for_each                      = var.internal_vnets_config
  name                          = "${each.key}-to-hub-route-table"
  location                      = data.azurerm_resource_group.resource_group.location
  resource_group_name           = data.azurerm_resource_group.resource_group.name
  disable_bgp_route_propagation = true
}

resource "azurerm_route" "spoke_to_hub" {
  for_each               = var.enable_router_vm ? var.internal_vnets_config : {}
  name                   = "to_hub"
  resource_group_name    = data.azurerm_resource_group.resource_group.name
  route_table_name       = azurerm_route_table.spoke_to_hub[each.key].name
  address_prefix         = var.supernet_cidr_range
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.router_nic[0].private_ip_address
}

resource "azurerm_route" "spoke_to_local" {
  for_each            = var.internal_vnets_config
  name                = "to_local"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  route_table_name    = azurerm_route_table.spoke_to_hub[each.key].name
  address_prefix      = each.value.cidr_range
  next_hop_type       = "VnetLocal"
}

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