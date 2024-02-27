data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "ingress_vpc" {
  name                = var.ingress_vnet_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "ingress_subnets" {
  for_each             = toset(data.azurerm_virtual_network.ingress_vpc.subnets)
  name                 = each.value
  virtual_network_name = data.azurerm_virtual_network.ingress_vpc.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}
