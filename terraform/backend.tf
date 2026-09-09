terraform {
  backend "azurerm" {

    use_oidc         = true # Nécessaire pour l'authentification sans secret dans GitHub Actions
    use_azuread_auth = true # Accès au blob par jeton Entra ID, sans clé de compte
  }
}