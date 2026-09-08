resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_key_vault" "kv" {
  # Key Vault names are capped at 24 chars, so the environment is truncated
  name                       = "kv-ads-${substr(replace(var.environment, "-", ""), 0, 6)}-${random_string.suffix.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "current_user_crypto_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = var.current_object_id
}

resource "azurerm_key_vault_key" "cmk" {
  name         = "velero-cmk"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 3072
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  
  depends_on = [azurerm_role_assignment.current_user_crypto_officer]
}