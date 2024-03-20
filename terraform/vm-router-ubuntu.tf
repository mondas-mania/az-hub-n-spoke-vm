###########
# SSH Key #
###########

resource "tls_private_key" "linux_ssh_key" {
  count     = var.enable_router_vm ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "linux_ssh_public_key" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-ubuntu-ssh-key"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  public_key          = tls_private_key.linux_ssh_key[0].public_key_openssh
}

resource "azurerm_key_vault_secret" "linux_ssh_private_key" {
  count        = var.enable_router_vm ? 1 : 0
  name         = "router-ubuntu-vm-ssh-private-key"
  value        = tls_private_key.linux_ssh_key[0].private_key_openssh
  key_vault_id = azurerm_key_vault.vm_key_vault.id
}

#######
# NIC #
#######

resource "azurerm_network_interface" "router_ubuntu_nic_primary" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-ubuntu-nic-primary"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "public"
    subnet_id                     = module.hub_vnet.vnet_subnets_name_id["hub-subnet-0"]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "router_ubuntu_nic_secondary" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-ubuntu-nic-secondary"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "private"
    subnet_id                     = module.hub_vnet.vnet_subnets_name_id["hub-subnet-0"]
    private_ip_address_allocation = "Dynamic"
  }
}

###################
# Virtual Machine #
###################

resource "azurerm_linux_virtual_machine" "router_ubuntu_vm" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-ubuntu-vm"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.router_ubuntu_nic_primary[0].id,
    azurerm_network_interface.router_ubuntu_nic_secondary[0].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = azurerm_ssh_public_key.linux_ssh_public_key[0].public_key
  }

  patch_mode = "AutomaticByPlatform"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

#######
# NSG #
#######

resource "azurerm_network_security_group" "router_ubuntu_nsg" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-ubuntu-vm-nsg"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_network_interface_security_group_association" "router_ubuntu_primary_nsg_assoc" {
  count                     = var.enable_router_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.router_ubuntu_nic_primary[0].id
  network_security_group_id = azurerm_network_security_group.router_ubuntu_nsg[0].id
}

resource "azurerm_network_interface_security_group_association" "router_ubuntu_secondary_nsg_assoc" {
  count                     = var.enable_router_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.router_ubuntu_nic_secondary[0].id
  network_security_group_id = azurerm_network_security_group.router_ubuntu_nsg[0].id
}

#####################
# Configure Routing #
#####################

# resource "azurerm_virtual_machine_extension" "configure_routing" {
#   count                = var.enable_router_vm ? 1 : 0
#   name                 = "configure_routing"
#   virtual_machine_id   = azurerm_windows_virtual_machine.router_vm[0].id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.9"

#   protected_settings = <<SETTINGS
#   {
#     "commandToExecute": "powershell -command \"Install-WindowsFeature RemoteAccess -IncludeManagementTools\" && powershell -command \"Install-WindowsFeature -Name Routing -IncludeManagementTools -IncludeAllSubFeature;Install-WindowsFeature -Name \"RSAT-RemoteAccess-Powershell\";Install-RemoteAccess -VpnType RoutingOnly;Get-NetAdapter | Set-NetIPInterface -Forwarding Enabled\""
#   }
#   SETTINGS
# }