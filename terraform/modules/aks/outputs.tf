output "cluster_name" { value = azurerm_kubernetes_cluster.aks.name }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.aks.oidc_issuer_url }
output "node_subnet_id" { value = azurerm_subnet.subnet.id }

output "host" {
  description = "L'URL du serveur d'API Kubernetes"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "client_certificate" {
  description = "Certificat client encodé en base64"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Clé client encodée en base64"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificat de l'autorité de certification (CA) encodé en base64"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}