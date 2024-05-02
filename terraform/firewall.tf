# to do
# https://learn.microsoft.com/en-us/azure/nat-gateway/tutorial-hub-spoke-nat-firewall#configure-network-rule
# - is there benefit in parameterising the SKU? premium SKU allows for easier testing bc of specific url filtering

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

resource "azurerm_firewall_policy_rule_collection_group" "firewall_policy_rule_collection" {
  count              = var.enable_central_firewall ? 1 : 0
  name               = "firewall-policy-rule-collection"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy[0].id
  priority           = 500
  application_rule_collection {
    name     = "allow_urls"
    priority = 500
    action   = "Allow"
    rule {
      name = "allow_google"
      protocols {
        type = "Https"
        port = 443
      }

      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = [var.supernet_cidr_range]
      destination_fqdns = [
        "*.google.com",
        "google.com"
      ]
    }

    rule {
      name = "allow_ifconfig_me"
      protocols {
        type = "Https"
        port = 443
      }

      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = [var.supernet_cidr_range]
      destination_fqdns = [
        "*.ifconfig.me",
        "ifconfig.me"
      ]
    }

    rule {
      name = "allow_windows_update_servers"
      # https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/2-configure-wsus#211-configure-your-firewall-to-allow-your-first-wsus-server-to-connect-to-microsoft-domains-on-the-internet
      # required to install WSI on the spoke VMs
      protocols {
        type = "Https"
        port = 443
      }

      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = [var.supernet_cidr_range]
      destination_fqdns = [
        "windowsupdate.microsoft.com",
        "*.windowsupdate.microsoft.com",
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "download.windowsupdate.com",
        "download.microsoft.com",
        "*.download.windowsupdate.com",
        "wustat.windows.com",
        "ntservicepack.microsoft.com",
        "go.microsoft.com",
        "dl.delivery.mp.microsoft.com",
        "*.delivery.mp.microsoft.com",
      ]
    }
  }
}
