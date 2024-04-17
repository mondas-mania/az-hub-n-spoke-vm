# to do
# 3. create Basic or Standard firewall resource (which can do fqdn filtering)
# 4. make sure central nat gateway will only attach to firewall subnet if enabled
# 5. make sure routing goes towards firewall - how will this work?
#  - https://learn.microsoft.com/en-us/azure/nat-gateway/tutorial-hub-spoke-nat-firewall#configure-network-rule
# 6. is there benefit in parameterising the SKU? premium SKU allows for easier testing bc of specific url filtering

locals {

}

resource "azurerm_public_ip" "firewall_pip" {
  count               = var.enable_central_firewall ? 1 : 0
  name                = "hub-firewall-pip"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "firewall_policy" {
  count               = var.enable_central_firewall ? 1 : 0
  name                = "hub-firewall-policy"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  sku                 = "Basic"
}

resource "azurerm_firewall" "firewall" {
  count               = var.enable_central_firewall ? 1 : 0
  name                = "hub-firewall"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.firewall_policy[0].id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.hub_vnet.vnet_subnets_name_id["AzureFirewallSubnet"]
    public_ip_address_id = azurerm_public_ip.firewall_pip[0].id
  }
}
