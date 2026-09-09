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

az group create --name "$TARGET_RG" --location "$LOCATION"

# Un create sur un compte existant relance une opération longue qui n'aboutit pas : on vérifie d'abord
if az storage account show --name "$STATE_SA" --resource-group "$TARGET_RG" &>/dev/null; then
  echo "ℹ️  Le compte de stockage '$STATE_SA' existe déjà, création ignorée."
else
  az storage account create \
    --name           "$STATE_SA" \
    --resource-group "$TARGET_RG" \
    --location       "$LOCATION" \
    --sku            Standard_LRS \
    --min-tls-version TLS1_2

  sleep 15
fi

# Attribution du rôle "Storage Blob Data Contributor" à l'utilisateur actuel pour le compte de stockage
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
STATE_SA_ID=$(az storage account show --name "$STATE_SA" --resource-group "$TARGET_RG" --query id -o tsv)

az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$CURRENT_USER_ID" \
  --assignee-principal-type User \
  --scope "$STATE_SA_ID"

# Création du conteneur pour le stockage distant avec gestion de la propagation du rôle RBAC
echo "Création du conteneur (attente de la propagation du rôle RBAC)..."
for attempt in $(seq 1 20); do
  if az storage container create \
    --name         "$STATE_CONTAINER" \
    --account-name "$STATE_SA" \
    --auth-mode    login 2>/dev/null; then
    echo "✅ Conteneur '$STATE_CONTAINER' disponible"
    break
  fi

  if [ "$attempt" -eq 20 ]; then
    echo "❌ Le rôle 'Storage Blob Data Contributor' n'est toujours pas effectif après 5 minutes."
    exit 1
  fi

  echo "   Tentative $attempt/20 : accès refusé, nouvelle tentative dans 15s..."
  sleep 15
done

az storage blob list \
  --container-name "$STATE_CONTAINER" \
  --account-name   "$STATE_SA" \
  --auth-mode      login \
  --output         table

# Désactivation de l'accès par clé partagée pour renforcer la sécurité
az storage account update \
  --name           "$STATE_SA" \
  --resource-group "$TARGET_RG" \
  --allow-shared-key-access false

sleep 15

cd terraform

terraform init \
  -backend-config="resource_group_name=${TARGET_RG}" \
  -backend-config="storage_account_name=${STATE_SA}" \
  -backend-config="container_name=$STATE_CONTAINER" \
  -backend-config="key=${OWNER}.terraform.tfstate" \
  -backend-config="use_azuread_auth=true" \
  -migrate-state