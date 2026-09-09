#!/bin/bash

# ==============================================================================
# Script de connexion rapide à l'interface locale d'ArgoCD
# ==============================================================================

# 1. Les variables sont définies ici (elles peuvent être adaptées selon l'environnement).
# Des valeurs par défaut sont utilisées, mais des arguments peuvent être passés au script.
RESOURCE_GROUP=${1:-"tenjalbertRG"}
CLUSTER_NAME=${2:-"aks-ads-non-production"}

echo "🚀 La connexion à ArgoCD pour le cluster $CLUSTER_NAME est initiée..."
echo "------------------------------------------------------------------"

# 2. Les accès au cluster AKS sont récupérés.
# Le terminal (kubectl) est connecté au cluster Azure via cette commande.
echo "🔄 1/3 - Les identifiants Kubernetes (kubeconfig) sont mis à jour..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
if [ $? -ne 0 ]; then
    echo "❌ Erreur : La connexion au cluster AKS a échoué. Les droits ou la connexion (az login) doivent être vérifiés."
    exit 1
fi

# 3. Le mot de passe administrateur d'ArgoCD est récupéré.
# Kubernetes est interrogé pour extraire le secret de la base de données. 
# Un jsonpath est utilisé pour cibler exactement le champ contenant le mot de passe.
echo "🔑 2/3 - Le mot de passe initial d'ArgoCD est récupéré..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "------------------------------------------------------------------"
echo "✅ SUCCÈS ! Les identifiants de connexion ont été récupérés :"
echo "👤 Utilisateur : admin"
echo "🔐 Mot de passe : $ARGOCD_PASSWORD"
echo "------------------------------------------------------------------"

# 4. Le tunnel vers l'interface web est ouvert.
# Le port-forward est lancé par la commande finale. 
# Le port 8080 local est redirigé vers le port 80 du pod (car le mode --insecure a été configuré).
echo "🌐 3/3 - Le tunnel vers l'interface web (Port-Forward) est ouvert..."
echo "⚠️  (Le terminal doit être laissé ouvert. Pour couper la connexion, la commande Ctrl+C doit être utilisée)"
echo "------------------------------------------------------------------"
echo "🔗 L'URL de connexion à utiliser dans le navigateur est : http://localhost:8080"
echo "------------------------------------------------------------------"

kubectl port-forward svc/argocd-server -n argocd 8080:80