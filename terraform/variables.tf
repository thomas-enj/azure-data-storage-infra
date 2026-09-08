variable "resource_group_name" {
  type        = string
  description = "Nom du groupe de ressources existant"
}

variable "location" {
  type        = string
  default     = "francecentral"
}

variable "aks_location" {
  type        = string
  default     = "westeurope"
  description = "Région spécifique pour le cluster AKS, le keyvault et le storage"
}

variable "environment" {
  type        = string
  default     = "non-production"
  description = "Environnement de déploiement"
}

variable "corporate_ip" {
  type        = string
  description = "IP publique de l'entreprise"
}

variable "employes_group_id" {
  type        = string
  description = "Object ID du groupe Entra ID 'employés'"
}

variable "gitops_repo_url" {
  type        = string
  description = "L'URL HTTPS du repository GitHub contenant les manifests pour ArgoCD"
}