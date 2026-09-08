output "storage_account_id" { value = azurerm_storage_account.sa.id }
output "storage_account_name" { value = azurerm_storage_account.sa.name }

output "workload_identity_client_id" {
  description = "Le Client ID à copier dans les manifestes ArgoCD (ServiceAccount et SecretProviderClass)"
  value       = module.identity.client_id
}

output "key_vault_name" {
  description = "Le nom du Key Vault à copier dans les manifestes ArgoCD (SecretProviderClass)"
  value       = module.keyvault.key_vault_name
}