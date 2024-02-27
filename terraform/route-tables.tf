resource "azurerm_route_table" "ingress_to_internal" {
  name                          = "ingress-to-internal-route-table"
  location                      = data.azurerm_resource_group.resource_group.location
  resource_group_name           = data.azurerm_resource_group.resource_group.name
  disable_bgp_route_propagation = true

  route {
    name                   = "to_internal"
    address_prefix         = module.internal_vnet.vnet_address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.router_nic.private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "ingress_rtb" {
  for_each       = toset([for name in data.azurerm_virtual_network.ingress_vpc.subnets : name if can(regex("private-subnet-[0-9]+", name))])
  subnet_id      = data.azurerm_subnet.ingress_subnets[each.value].id
  route_table_id = azurerm_route_table.ingress_to_internal.id
}

resource "azurerm_route_table" "internal_to_ingress" {
  name                          = "internal-to-ingress-route-table"
  location                      = data.azurerm_resource_group.resource_group.location
  resource_group_name           = data.azurerm_resource_group.resource_group.name
  disable_bgp_route_propagation = true

  route {
    name                   = "to_ingress"
    address_prefix         = data.azurerm_virtual_network.ingress_vpc.address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.router_nic.private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "internal_rtb" {
  for_each       = module.internal_vnet.vnet_subnets_name_id
  subnet_id      = each.value
  route_table_id = azurerm_route_table.internal_to_ingress.id
}