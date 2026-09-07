#!/bin/bash
set -e

# (Fix)Empêche la conversion automatique des chemins par Git Bash sous Windows
export MSYS_NO_PATHCONV=1

# Chargement des variables depuis le fichier ignoré par Git
if [ -f "vars.env" ]; then
  source vars.env
  echo "✅ Variables chargées depuis vars.env"
else
  echo "❌ Erreur : Le fichier vars.env est introuvable."
  exit 1
fi

# Vérification de sécurité
REQUIRED_VARS=("GITHUB_ORG" "GITHUB_REPO" "TARGET_RG" "STATE_RG" "STATE_SA" "IDENTITY_NAME" "BRANCH")
for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "❌ Erreur : La variable $VAR n'est pas définie dans vars.env."
    exit 1
  fi
done

echo "Récupération du contexte Azure..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Création de l'identité managée '$IDENTITY_NAME'..."
az identity create --name "$IDENTITY_NAME" --resource-group "$TARGET_RG"

CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$TARGET_RG" --query 'clientId' -o tsv)
PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$TARGET_RG" --query 'principalId' -o tsv)
TARGET_RG_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$TARGET_RG"
STATE_SA_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$STATE_RG/providers/Microsoft.Storage/storageAccounts/$STATE_SA"

# Temporisation pour la propagation côté Azure AD
sleep 15

echo "Attribution des droits stricts (Least Privilege)..."
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "$STATE_SA_ID"

az role assignment create \
  --role "Contributor" \
  --assignee-object-id "$PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "$TARGET_RG_ID"

az role assignment create \
  --role "Role Based Access Control Administrator" \
  --assignee-object-id "$PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "$TARGET_RG_ID"

echo "Création de la fédération OIDC pour la branche $BRANCH..."
az identity federated-credential create \
  --name "github-actions-federation-branch" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$TARGET_RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/$BRANCH" \
  --audience "api://AzureADTokenExchange"

echo "Création de la fédération OIDC pour les Pull Requests..."
az identity federated-credential create \
  --name "github-actions-federation-pr" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$TARGET_RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:pull_request" \
  --audience "api://AzureADTokenExchange"

echo "Création de la fédération OIDC pour l'environnement tf-apply..."
az identity federated-credential create \
  --name "github-actions-federation-env-apply" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$TARGET_RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:environment:tf-apply" \
  --audience "api://AzureADTokenExchange"

echo "Création de la fédération OIDC pour l'environnement tf-destroy..."
az identity federated-credential create \
  --name "github-actions-federation-env-destroy" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$TARGET_RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:environment:tf-destroy" \
  --audience "api://AzureADTokenExchange"

echo ""
echo "=== Création de l'identité managée et configuration OIDC terminée ==="
echo "Les valeurs à ajouter dans les secrets du repository GitHub sont :"
echo "AZURE_CLIENT_ID: $CLIENT_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"