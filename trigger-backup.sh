#!/bin/bash

# Définition du namespace cible (par défaut: database-ns)
NAMESPACE=${1:-database-ns}

# Création d'un horodatage précis pour garantir un nom de backup unique
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="${NAMESPACE}-backup-${TIMESTAMP}"

echo "🚀 Déclenchement de la sauvegarde Velero..."
echo "📂 Namespace ciblé : $NAMESPACE"
echo "📦 Nom de la sauvegarde : $BACKUP_NAME"

# Création dynamique de la ressource Kubernetes
cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: ${BACKUP_NAME}
  namespace: velero
spec:
  includedNamespaces:
  - ${NAMESPACE}
  storageLocation: default
  volumeSnapshotLocations:
  - default
EOF

echo "---"
echo "✅ Demande de sauvegarde envoyée avec succès !"
echo "👀 Pour suivre l'avancement en temps réel, exécutez :"
echo "kubectl get backups.velero.io -n velero -w"
echo "📌 Pour obtenir les détails d'une sauvegarde spécifique, exécutez :"
echo "kubectl describe backup ${BACKUP_NAME} -n velero"