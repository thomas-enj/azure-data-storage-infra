variable "resource_group_name" {
  type        = string
  description = "Nom du groupe de ressources existant"
}

variable "location" {
  type        = string
  default     = "francecentral"
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