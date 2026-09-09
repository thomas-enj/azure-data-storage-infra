resource "azurerm_user_assigned_identity" "velero" {
  name                = "ads-workload-identity-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "velero_storage_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.velero.principal_id
}

resource "azurerm_role_assignment" "velero_storage_reader" {
  scope                = var.storage_account_id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.velero.principal_id
}

resource "azurerm_federated_identity_credential" "velero" {
  name                      = "velero-federated-credential"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.aks_oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.velero.id
  subject                   = "system:serviceaccount:velero:velero"
}

resource "azurerm_federated_identity_credential" "mysql" {
  name                      = "mysql-federated-credential"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.aks_oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.velero.id
  subject                   = "system:serviceaccount:database-ns:mysql-sa"
}