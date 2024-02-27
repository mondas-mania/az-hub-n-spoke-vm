#######
# NIC #
#######

resource "azurerm_network_interface" "webserver_nic" {
  count               = var.enable_webserver ? 1 : 0
  name                = "webserver-nic"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.internal_vnet.vnet_subnets_name_id["private-subnet-0"]
    private_ip_address_allocation = "Dynamic"
  }
}

###################
# Virtual Machine #
###################

resource "azurerm_windows_virtual_machine" "webserver_vm" {
  count               = var.enable_webserver ? 1 : 0
  name                = "webserver-vm"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = var.router_password
  network_interface_ids = [
    azurerm_network_interface.webserver_nic[0].id,
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
  count               = var.enable_webserver ? 1 : 0
  name                = "webserver-vm-router"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_network_interface_security_group_association" "webserver_nsg_assoc" {
  count                     = var.enable_webserver ? 1 : 0
  network_interface_id      = azurerm_network_interface.webserver_nic[0].id
  network_security_group_id = azurerm_network_security_group.webserver_nsg[0].id
}

resource "azurerm_network_security_rule" "http_windows" {
  count                       = var.enable_webserver ? 1 : 0
  name                        = "HTTPInternalVNets"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "80"
  destination_port_range      = "80"
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.webserver_nsg[0].name
}

#######################
# Configure Webserver #
#######################

resource "azurerm_virtual_machine_extension" "web_server_install" {
  count                      = var.enable_webserver ? 1 : 0
  name                       = "configure-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.webserver_vm[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}
