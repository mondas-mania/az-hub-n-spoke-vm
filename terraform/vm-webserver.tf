locals {
  # web_server_vnets = toset([for vnet_name, vnet_config in var.internal_vnets_config : vnet_name if vnet_config.deploy_wsi])
  # "wsi-${substr(each.value, 0, 3)}-${element(split("-", each.value), length(split("-", each.value)) - 1)}"
  web_server_vnets = { for vnet_name, vnet_config in var.internal_vnets_config : vnet_name => "wsi-${substr(vnet_name, 0, 3)}-${element(split("-", vnet_name), length(split("-", vnet_name)) - 1)}" if vnet_config.deploy_wsi }
}

######################
# Key Vault Password #
######################

resource "azurerm_key_vault_secret" "webserver_password" {
  for_each     = local.web_server_vnets
  name         = "${each.value}-password"
  value        = var.router_password
  key_vault_id = azurerm_key_vault.vm_key_vault.id
}

#######
# NIC #
#######

resource "azurerm_network_interface" "webserver_nic" {
  for_each            = local.web_server_vnets
  name                = "webserver-nic-${each.key}"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name      = "internal"
    subnet_id = module.spoke_vnet[each.key].vnet_subnets_name_id["private-subnet-0"]
    # will fail if num_subnets is set to 0, but that's a useless use case
    private_ip_address_allocation = "Dynamic"
  }
}

###################
# Virtual Machine #
###################

resource "azurerm_windows_virtual_machine" "webserver_vm" {
  for_each            = local.web_server_vnets
  name                = each.value
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.webserver_password[each.key].value
  network_interface_ids = [
    azurerm_network_interface.webserver_nic[each.key].id,
  ]

  patch_mode = "AutomaticByPlatform"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

#######
# NSG #
#######

resource "azurerm_network_security_group" "webserver_nsg" {
  count               = length(local.web_server_vnets) > 0 ? 1 : 0
  name                = "webserver-vm-nsg"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_network_interface_security_group_association" "webserver_nsg_assoc" {
  for_each                  = local.web_server_vnets
  network_interface_id      = azurerm_network_interface.webserver_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.webserver_nsg[0].id
}

resource "azurerm_network_security_rule" "http_windows_inbound" {
  count                       = length(local.web_server_vnets) > 0 ? 1 : 0
  name                        = "HTTPInternalVNets"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*" # Azure portal recommends * for source port, filtering should be done at destination level
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.webserver_nsg[0].name
}

# trivy:ignore:AVD-AZU-0051
resource "azurerm_network_security_rule" "http_windows_outbound" {
  count                       = length(local.web_server_vnets) > 0 ? 1 : 0
  name                        = "HTTPOutboundVNets"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*" # Azure portal recommends * for source port, filtering should be done at destination level
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.webserver_nsg[0].name
}

#######################
# Configure Webserver #
#######################

resource "azurerm_virtual_machine_extension" "web_server_install" {
  for_each                   = local.web_server_vnets
  name                       = "configure-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.webserver_vm[each.key].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools && powershell Remove-Item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS
}
