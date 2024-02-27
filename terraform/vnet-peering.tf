##################
# Hub to Ingress #
##################

resource "azurerm_virtual_network_peering" "hub_to_ingress" {
  name                      = "hub-to-ingress-peering"
  resource_group_name       = data.azurerm_resource_group.resource_group.name
  virtual_network_name      = module.hub_vnet.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.ingress_vpc.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  triggers = {
    remote_address_space = join(",", data.azurerm_virtual_network.ingress_vpc.address_space)
  }
}

resource "azurerm_virtual_network_peering" "ingress_to_hub" {
  name                      = "ingress-to-hub-peering"
  resource_group_name       = data.azurerm_resource_group.resource_group.name
  virtual_network_name      = data.azurerm_virtual_network.ingress_vpc.name
  remote_virtual_network_id = module.hub_vnet.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  triggers = {
    remote_address_space = join(",", module.hub_vnet.vnet_address_space)
  }

  depends_on = [azurerm_virtual_network_peering.hub_to_ingress]
}

###################
# Hub to Internal #
###################

resource "azurerm_virtual_network_peering" "hub_to_internal" {
  name                      = "hub-to-internal-peering"
  resource_group_name       = data.azurerm_resource_group.resource_group.name
  virtual_network_name      = module.hub_vnet.vnet_name
  remote_virtual_network_id = module.internal_vnet.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  triggers = {
    remote_address_space = join(",", module.internal_vnet.vnet_address_space)
  }
}

resource "azurerm_virtual_network_peering" "internal_to_hub" {
  name                      = "internal-to-hub-peering"
  resource_group_name       = data.azurerm_resource_group.resource_group.name
  virtual_network_name      = module.internal_vnet.vnet_name
  remote_virtual_network_id = module.hub_vnet.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  triggers = {
    remote_address_space = join(",", module.hub_vnet.vnet_address_space)
  }

  depends_on = [azurerm_virtual_network_peering.hub_to_internal]
}
