resource "random_string" "key_vault_random_string" {
  length  = 10
  numeric = true
  special = false
  upper   = false
}

# Copied from TF docs example
# trivy:ignore:AVD-AZU-0016
# trivy:ignore:AVD-AZU-0013
resource "azurerm_key_vault" "vm_key_vault" {
  name                        = "vm-key-vault-${random_string.key_vault_random_string.id}"
  location                    = data.azurerm_resource_group.resource_group.location
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}
