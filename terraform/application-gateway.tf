locals {
  # courtesy of terraform docs example
  backend_address_pool_name      = "web-servers-backend-pool"
  frontend_port_name             = "port-80"
  frontend_ip_configuration_name = "frontend-ip"
  http_setting_name              = "http-config"
  listener_name                  = "http-listener"
  request_routing_rule_name      = "request-routing-rule"
  url_path_map_name              = "url-path-map"
  path_rule_name                 = "path-rule"

  app_gws = {
    for vnet_name, vnet_config in var.internal_vnets_config : vnet_name => {
      name                      = "app-gateway-${vnet_name}"
      listener_name             = local.listener_name
      request_routing_rule_name = local.request_routing_rule_name
      url_path_map_name         = local.url_path_map_name
      paths = merge({
        "/" = {
          ip_addresses              = [for target in vnet_config.app_gw_config.target_vnets : azurerm_windows_virtual_machine.webserver_vm[target].private_ip_address]
          http_setting_name         = "${local.http_setting_name}-default"
          request_routing_rule_name = "${local.request_routing_rule_name}-default"
          backend_address_pool_name = "${local.backend_address_pool_name}-default"
          path_rule_name            = "${local.path_rule_name}-default"
        }
        },
        {
          for target in vnet_config.app_gw_config.target_vnets : "/${target}/" => {
            ip_addresses              = [azurerm_windows_virtual_machine.webserver_vm[target].private_ip_address]
            http_setting_name         = "${local.http_setting_name}-${target}"
            request_routing_rule_name = "${local.request_routing_rule_name}-${target}"
            backend_address_pool_name = "${local.backend_address_pool_name}-${target}"
            path_rule_name            = "${local.path_rule_name}-${target}"
          }
        }
      )
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

resource "azurerm_application_gateway" "application_gateway" {
  for_each            = local.app_gws
  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.spoke_vnet[each.key].vnet_subnets_name_id["AppGWSubnet"]
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gateway_pip[each.key].id
  }

  dynamic "backend_address_pool" {
    for_each = each.value.paths
    content {
      name         = backend_address_pool.value.backend_address_pool_name
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = each.value.paths
    content {
      name                  = backend_http_settings.value.http_setting_name
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 60
    }
  }

  request_routing_rule {
    name               = each.value.request_routing_rule_name
    priority           = 9
    rule_type          = "PathBasedRouting"
    http_listener_name = each.value.listener_name
    url_path_map_name  = each.value.url_path_map_name
  }

  url_path_map {
    name                               = each.value.url_path_map_name
    default_backend_address_pool_name  = each.value.paths["/"].backend_address_pool_name
    default_backend_http_settings_name = each.value.paths["/"].http_setting_name

    dynamic "path_rule" {
      for_each = { for path, values in each.value.paths : path => values if path != "/" }
      content {
        name                       = path_rule.value.path_rule_name
        paths                      = [path_rule.key]
        backend_address_pool_name  = path_rule.value.backend_address_pool_name
        backend_http_settings_name = path_rule.value.http_setting_name
      }
    }
  }
}
