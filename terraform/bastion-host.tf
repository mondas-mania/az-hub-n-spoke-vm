locals {
  bastion_hosts = toset([for vnet_name, vnet_config in var.internal_vnets_config : vnet_name if vnet_config.enable_bastion])
}

resource "azurerm_public_ip" "bastion_pip" {
  for_each            = local.bastion_hosts
  name                = "bastion-pip-${each.key}"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  for_each            = local.bastion_hosts
  name                = "bastion-host-${each.key}"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.spoke_vnet[each.key].vnet_subnets_name_id["AzureBastionSubnet"]
    public_ip_address_id = azurerm_public_ip.bastion_pip[each.key].id
  }
}
