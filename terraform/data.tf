data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}
