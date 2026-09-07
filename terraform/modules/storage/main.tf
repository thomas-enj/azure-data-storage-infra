resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "velerostg${replace(var.environment, "-", "")}${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  
  # Contrainte appliquée : LRS au lieu de GRS
  account_replication_type = "LRS" 

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = [var.corporate_ip]
    virtual_network_subnet_ids = [var.aks_subnet_id]
  }
  
  # Contrainte appliquée : Pas de soft delete activé explicitement
}

resource "azurerm_role_assignment" "sa_kv_crypto" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.sa.identity[0].principal_id
}

resource "azurerm_storage_account_customer_managed_key" "cmk" {
  storage_account_id = azurerm_storage_account.sa.id
  key_vault_id       = var.key_vault_id
  key_name           = var.key_vault_key_name
  depends_on         = [azurerm_role_assignment.sa_kv_crypto]
}

resource "azurerm_storage_container" "velero" {
  name                  = "velero"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
  depends_on            = [azurerm_storage_account_customer_managed_key.cmk]
}