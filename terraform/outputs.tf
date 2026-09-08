output "workload_identity_client_id" {
  description = "Le Client ID à copier dans les manifestes ArgoCD (ServiceAccount et SecretProviderClass)"
  value       = module.identity.client_id
}

output "key_vault_id" {
  description = "L'ID du Key Vault à copier dans les manifestes ArgoCD (SecretProviderClass)"
  value       = module.keyvault.key_vault_id
}