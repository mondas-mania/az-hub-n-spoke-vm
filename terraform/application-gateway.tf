locals {
  app_gws = {
    for vnet_name, vnet_config in var.internal_vnets_config : vnet_name => {
      target_ips = [for target in vnet_config.app_gw_config.target_vnets : azurerm_windows_virtual_machine.webserver_vm[target].private_ip_address]
    } if vnet_config.app_gw_config.deploy_app_gw
  }
}

resource "azurerm_public_ip" "app_gateway_pip" {
  for_each            = local.app_gws
  name                = "app-gw-pip-${each.key}"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# courtesy of terraform docs example
locals {
  backend_address_pool_name      = "web-servers-backend-pool"
  frontend_port_name             = "port-80"
  frontend_ip_configuration_name = "frontend-ip"
  http_setting_name              = "http-config"
  listener_name                  = "http-listener"
  request_routing_rule_name      = "request-routing-rule"
}

resource "azurerm_application_gateway" "application_gateway" {
  for_each            = local.app_gws
  name                = "app-gateway-${each.key}"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.spoke_vnet[each.key].vnet_subnets_name_id["private-subnet-0"]
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gateway_pip[each.key].id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = each.value.target_ips
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
