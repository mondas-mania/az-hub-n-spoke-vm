########################
# Hub to Spoke Peering #
########################

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.internal_vnets_config

  name                      = "hub-to-${each.key}-peering"
  resource_group_name       = data.azurerm_resource_group.resource_group.name
  virtual_network_name      = module.hub_vnet.vnet_name
  remote_virtual_network_id = module.spoke_vnet[each.key].vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  triggers = {
    remote_address_space = join(",", module.spoke_vnet[each.key].vnet_address_space)
  }
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = var.internal_vnets_config
  name                      = "${each.key}-to-hub-peering"
  resource_group_name       = data.azurerm_resource_group.resource_group.name
  virtual_network_name      = module.spoke_vnet[each.key].vnet_name
  remote_virtual_network_id = module.hub_vnet.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  triggers = {
    remote_address_space = join(",", module.hub_vnet.vnet_address_space)
  }

  depends_on = [azurerm_virtual_network_peering.hub_to_spoke]
}
