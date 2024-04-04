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

resource "azurerm_network_interface" "router_ubuntu_nic_private" {
  count               = var.enable_router_vm ? 1 : 0
  name                = "router-ubuntu-nic-private"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  enable_ip_forwarding = true

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
    azurerm_network_interface.router_ubuntu_nic_private[0].id, # eth0
  ]


  # https://medium.com/contino-engineering/azure-egress-nat-with-linux-vm-595f6abd2f77
  # https://learn.microsoft.com/en-us/azure/nat-gateway/tutorial-hub-spoke-route-nat
  # adapted both, ignoring the "public" network interface in the first link due to the NAT Gateway
  custom_data = base64encode(file("${path.module}/scripts/ubuntu-routing.sh"))

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

resource "azurerm_network_security_rule" "http_router_inbound" {
  count                       = var.enable_router_vm ? 1 : 0
  name                        = "HTTPInboundRouter"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*" # Azure portal recommends * for source port, filtering should be done at destination level
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.router_ubuntu_nsg[0].name
}

resource "azurerm_network_security_rule" "http_router_outbound" {
  count                       = var.enable_router_vm ? 1 : 0
  name                        = "HTTPOutboundRouter"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*" # Azure portal recommends * for source port, filtering should be done at destination level
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.router_ubuntu_nsg[0].name
}

resource "azurerm_network_interface_security_group_association" "router_ubuntu_private_nsg_assoc" {
  count                     = var.enable_router_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.router_ubuntu_nic_private[0].id
  network_security_group_id = azurerm_network_security_group.router_ubuntu_nsg[0].id
}
