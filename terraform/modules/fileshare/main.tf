resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_storage_account" "fs_sa" {
  name                     = "empfs${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  azure_files_authentication {
    directory_type = "AADKERB"
  }
}

resource "azurerm_storage_share" "fs" {
  name               = "employes-share"
  storage_account_id = azurerm_storage_account.fs_sa.id
  quota              = 50
}

resource "azurerm_role_assignment" "fs_contributor" {
  scope                = azurerm_storage_account.fs_sa.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = var.employes_group_id
}
