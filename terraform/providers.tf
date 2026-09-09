terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    helm = {
      source  = "hashicorp/helm",
      version = "~> 2.14"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Garde de key vault en soft-delete sur le destroy et le réutilise lors du prochain apply.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
      recover_soft_deleted_keys       = true
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}