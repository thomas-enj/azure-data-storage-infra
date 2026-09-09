#!/bin/bash
set -e

# Chargement des variables depuis le fichier ignoré par Git
if [ -f "vars.env" ]; then
  source vars.env
  echo "✅ Variables chargées depuis vars.env"
else
  echo "❌ Erreur : Le fichier vars.env est introuvable."
  exit 1
fi

az group create --name "$TARGET_RG" --location "$LOCATION"

az storage account create \
  --name           "$STATE_SA" \
  --resource-group "$TARGET_RG" \
  --location       "$LOCATION" \
  --sku            Standard_LRS \
  --min-tls-version TLS1_2

sleep 15

# Attribution du rôle "Storage Blob Data Contributor" à l'utilisateur actuel pour le compte de stockage
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
STATE_SA_ID=$(az storage account show --name "$STATE_SA" --resource-group "$TARGET_RG" --query id -o tsv)

az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$CURRENT_USER_ID" \
  --assignee-principal-type User \
  --scope "$STATE_SA_ID"

# Temporisation pour la propagation du rôle RBAC
sleep 30

az storage container create \
  --name         "$STATE_CONTAINER" \
  --account-name "$STATE_SA" \
  --auth-mode    login

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
  -migrate-state