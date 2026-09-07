output "cluster_name" { value = azurerm_kubernetes_cluster.aks.name }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.aks.oidc_issuer_url }
output "node_subnet_id" { value = azurerm_subnet.subnet.id }