#!/bin/bash
set -e

# (Fix)Empêche la conversion automatique des chemins par Git Bash sous Windows
export MSYS_NO_PATHCONV=1

echo "Vérification de l'existence du groupe Entra ID 'employés'..."

# On cherche si le groupe existe déjà (insensible à la casse)
GROUP_ID=$(az ad group list --display-name "employés" --query "[0].id" -o tsv)

if [ -z "$GROUP_ID" ]; then
  echo "Création du groupe 'employés'..."
  # Création du groupe de sécurité
  GROUP_ID=$(az ad group create --display-name "employés" --mail-nickname "employes" --query "id" -o tsv)
  echo "✅ Groupe créé avec succès."
else
  echo "✅ Le groupe existe déjà."
fi

echo ""
echo "=== Création du groupe 'employés' terminée ==="
echo "La valeur suivante doit être utilisée dans les variables du repository GitHub :"
echo "TF_VAR_employes_group_id: $GROUP_ID"