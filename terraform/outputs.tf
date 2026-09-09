output "workload_identity_client_id" {
  description = "Le Client ID à copier dans les manifestes ArgoCD (ServiceAccount et SecretProviderClass)"
  value       = module.identity.client_id
}

output "key_vault_id" {
  description = "L'ID du Key Vault à copier dans les manifestes ArgoCD (SecretProviderClass)"
  value       = module.keyvault.key_vault_id
}

output "tenant_id" {
  description = "Le Tenant ID Azure à copier dans les manifestes ArgoCD (SecretProviderClass)"
  value       = data.azurerm_client_config.current.tenant_id
}