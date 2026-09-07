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
  --sku            Standard_LRS

sleep 15

az storage container create \
  --name         "$STATE_CONTAINER" \
  --account-name "$STATE_SA"

az storage blob list \
  --container-name "$STATE_CONTAINER" \
  --account-name   "$STATE_SA" \
  --output         table

sleep 15

cd terraform

terraform init \
  -backend-config="resource_group_name=${TARGET_RG}" \
  -backend-config="storage_account_name=${STATE_SA}" \
  -backend-config="container_name=$STATE_CONTAINER" \
  -backend-config="key=${OWNER}.terraform.tfstate" \
  -migrate-state