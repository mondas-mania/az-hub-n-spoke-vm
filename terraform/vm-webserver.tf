############
# Password #
############

# resource "azurerm_key_vault_secret" "windows_password" {
#   name         = "windows-vm-password"
#   value        = var.windows_password
#   key_vault_id = azurerm_key_vault.vm_key_vault.id
# }

#######
# NIC #
#######

resource "azurerm_network_interface" "webserver_nic" {
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
  name                = "webserver-vm"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = var.router_password
  network_interface_ids = [
    azurerm_network_interface.webserver_nic.id,
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
  name                = "webserver-vm-router"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_network_interface_security_group_association" "webserver_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.webserver_nic.id
  network_security_group_id = azurerm_network_security_group.webserver_nsg.id
}

resource "azurerm_network_security_rule" "http_windows" {
  name                        = "HTTPInternet"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.webserver_nsg.name
}

#######################
# Configure Webserver #
#######################

resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = "configure-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.webserver_vm.id
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
