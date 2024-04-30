resource "azurerm_route_table" "hub_rtb" {
  name                          = "hub-vnet-route-table"
  location                      = data.azurerm_resource_group.resource_group.location
  resource_group_name           = data.azurerm_resource_group.resource_group.name
  disable_bgp_route_propagation = true
}

resource "azurerm_route" "router_to_firewall" {
  count                  = var.enable_central_firewall && var.enable_router_vm ? 1 : 0
  name                   = "to_firewall"
  resource_group_name    = data.azurerm_resource_group.resource_group.name
  route_table_name       = azurerm_route_table.hub_rtb.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "hub_rtb_assoc" {
  subnet_id      = module.hub_vnet.vnet_subnets_name_id["hub-subnet-0"]
  route_table_id = azurerm_route_table.hub_rtb.id
}
