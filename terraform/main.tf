data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.aks_location
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id
  current_object_id   = data.azurerm_client_config.current.object_id
}

module "aks" {
  source              = "./modules/aks"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.aks_location
  environment         = var.environment
}

module "storage" {
  source              = "./modules/storage"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.aks_location
  environment         = var.environment
  corporate_ip        = var.corporate_ip
  aks_subnet_id       = module.aks.node_subnet_id
  key_vault_id        = module.keyvault.key_vault_id
  key_vault_key_id    = module.keyvault.key_vault_key_id
}

module "identity" {
  source              = "./modules/identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  environment         = var.environment
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  storage_account_id  = module.storage.storage_account_id
}

module "fileshare" {
  source              = "./modules/fileshare"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.aks_location
  employes_group_id   = var.employes_group_id
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.4.4"
  namespace        = "argocd"
  create_namespace = true

  # Le cluster AKS doit être créé AVANT d'essayer d'y installer ArgoCD
  depends_on = [module.aks]

  set {
    name  = "server.extraArgs"
    value = "{--insecure}" # Désactive le TLS interne pour simplifier l'accès local
  }
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.1"
  namespace  = "argocd"

  # ArgoCD doit être installé avant de configurer l'application.
  depends_on = [helm_release.argocd]

  values = [
    yamlencode({
      applications = {
        gitops-bootstrap = {
          namespace = "argocd"
          project   = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = "main"
            path           = "manifests"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "default"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
          }
        }
      }
    })
  ]
}