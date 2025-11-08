#!/bin/bash

# Script de configuration GCP pour l'agent scolaire multi-agent
# Ce script configure automatiquement votre environnement GCP

set -e  # Arrêter en cas d'erreur

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   Configuration Google Cloud Platform                          ║"
echo "║   Agent Scolaire Multi-Agent                                   ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    error "gcloud CLI n'est pas installé"
    echo "Installez-le depuis : https://cloud.google.com/sdk/docs/install"
    exit 1
fi

success "gcloud CLI trouvé"
echo ""

# 1. Lister les projets disponibles
info "Vos projets Google Cloud :"
echo ""
gcloud projects list --format="table(projectId,name,projectNumber)"
echo ""

# 2. Demander le PROJECT_ID
read -p "Entrez l'ID de votre projet GCP (PROJECT_ID) : " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    error "PROJECT_ID ne peut pas être vide"
    exit 1
fi

info "Vérification du projet $PROJECT_ID..."
if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    error "Le projet $PROJECT_ID n'existe pas ou vous n'y avez pas accès"
    exit 1
fi

success "Projet $PROJECT_ID trouvé"
echo ""

# 3. Configurer le projet par défaut
info "Configuration du projet par défaut..."
gcloud config set project "$PROJECT_ID"
success "Projet configuré : $PROJECT_ID"
echo ""

# 4. Authentification
info "Configuration de l'authentification..."
info "Une fenêtre de navigateur va s'ouvrir pour l'authentification..."
echo ""

if gcloud auth application-default login --project="$PROJECT_ID"; then
    success "Authentification réussie"
else
    warning "Authentification échouée, tentative alternative..."
    gcloud auth login
    gcloud auth application-default set-quota-project "$PROJECT_ID"
fi
echo ""

# 5. Activer les APIs nécessaires
info "Activation des APIs Google Cloud..."
echo ""

info "  → Activation de Vertex AI API..."
if gcloud services enable aiplatform.googleapis.com --project="$PROJECT_ID" 2>/dev/null; then
    success "  ✓ Vertex AI API activée"
else
    warning "  ⚠ Vertex AI API déjà activée ou erreur"
fi

info "  → Activation de Vertex AI Search (Discovery Engine)..."
if gcloud services enable discoveryengine.googleapis.com --project="$PROJECT_ID" 2>/dev/null; then
    success "  ✓ Discovery Engine API activée"
else
    warning "  ⚠ Discovery Engine API déjà activée ou erreur"
fi

info "  → Activation de Cloud Storage API..."
if gcloud services enable storage.googleapis.com --project="$PROJECT_ID" 2>/dev/null; then
    success "  ✓ Cloud Storage API activée"
else
    warning "  ⚠ Cloud Storage API déjà activée ou erreur"
fi

echo ""

# 6. Vérification de la configuration
info "Vérification de la configuration..."
echo ""

echo "📋 Configuration actuelle :"
echo "  • Projet actif : $(gcloud config get-value project)"
echo "  • Compte : $(gcloud config get-value account)"
echo "  • Région : $(gcloud config get-value compute/region || echo 'non définie')"
echo ""

echo "🔌 APIs activées :"
gcloud services list --enabled --project="$PROJECT_ID" --filter="name:(aiplatform.googleapis.com OR discoveryengine.googleapis.com)" --format="table(name)" | tail -n +2 | while read api; do
    echo "  ✓ $api"
done
echo ""

# 7. Créer le fichier .env si nécessaire
info "Création du fichier .env..."
cat > .env << EOF
# Configuration Google Cloud Platform
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
GOOGLE_CLOUD_LOCATION=us-central1
GOOGLE_GENAI_USE_VERTEXAI=True

# Configuration du Data Store (à ajuster selon votre setup)
DATA_STORE_ID=mon-agent-scolaire-datastore
DATA_STORE_REGION=us
EOF

success "Fichier .env créé"
echo ""

# 8. Résumé final
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   ✅ Configuration terminée avec succès !                      ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

success "Vous pouvez maintenant lancer le playground :"
echo ""
echo "  make playground"
echo ""

info "Pour déployer sur Vertex AI :"
echo ""
echo "  make backend"
echo ""

info "Fichiers créés/modifiés :"
echo "  • .env (configuration du projet)"
echo "  • Configuration gcloud mise à jour"
echo ""

echo ""

