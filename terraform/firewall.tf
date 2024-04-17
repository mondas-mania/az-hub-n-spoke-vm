# to do
# 1. create PIP (standard, static)
# 2. create basic firewall policy (firewall rules are outdated)
# 3. create firewall resource
# 4. make sure central nat gateway will only attach to firewall subnet if enabled
# 5. make sure routing goes towards firewall - how will this work?

locals {

}

resource "azurerm_public_ip" "firewall_pip" {
  name                = "hub-firewall-pip"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
