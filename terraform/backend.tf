terraform {
  backend "azurerm" {
    
    use_oidc = true # Nécessaire pour l'authentification sans secret dans GitHub Actions
  }
}