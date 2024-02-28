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

resource "azurerm_network_interface" "router_nic" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-nic"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.hub_vnet.vnet_subnets_name_id["hub-subnet-0"]
    private_ip_address_allocation = "Dynamic"
  }
}

###################
# Virtual Machine #
###################

resource "azurerm_windows_virtual_machine" "router_vm" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-vm"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = var.router_password
  network_interface_ids = [
    azurerm_network_interface.router_nic[0].id,
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

resource "azurerm_network_security_group" "router_nsg" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-vm-router"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_network_interface_security_group_association" "router_nsg_assoc" {
  count                     = var.enable_router_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.router_nic[0].id
  network_security_group_id = azurerm_network_security_group.router_nsg[0].id
}

#####################
# Configure Routing #
#####################

resource "azurerm_virtual_machine_extension" "configure_routing" {
  count                = var.enable_router_vm ? 1 : 0
  name                 = "configure_routing"
  virtual_machine_id   = azurerm_windows_virtual_machine.router_vm[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"Install-WindowsFeature RemoteAccess -IncludeManagementTools\" && powershell -command \"Install-WindowsFeature -Name Routing -IncludeManagementTools -IncludeAllSubFeature;Install-WindowsFeature -Name \"RSAT-RemoteAccess-Powershell\";Install-RemoteAccess -VpnType RoutingOnly;Get-NetAdapter | Set-NetIPInterface -Forwarding Enabled\""
  }
  SETTINGS
}
