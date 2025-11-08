#!/bin/bash

# Script de réinstallation complète pour corriger les problèmes d'installation
# Usage: ./install_fix.sh

set -e 

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   🔧 Réinstallation Complète des Dépendances                  ║"
echo "║   Agent Scolaire Multi-Agent                                   ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 1. Vérifier que uv est installé
info "Vérification de uv..."
if ! command -v uv &> /dev/null; then
    warning "uv n'est pas installé. Installation..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi
success "uv trouvé : $(uv --version)"
echo ""

# 2. Sauvegarder l'ancien environnement
if [ -d ".venv" ]; then
    info "Sauvegarde de l'ancien environnement..."
    mv .venv .venv.backup.$(date +%Y%m%d_%H%M%S) || true
    success "Ancien environnement sauvegardé"
fi
echo ""

# 3. Supprimer le lock file obsolète
if [ -f "uv.lock" ]; then
    info "Suppression du lock file obsolète..."
    mv uv.lock uv.lock.backup.$(date +%Y%m%d_%H%M%S) || true
    success "Lock file sauvegardé"
fi
echo ""

# 4. Nettoyer le cache uv
info "Nettoyage du cache uv..."
uv cache clean || true
success "Cache nettoyé"
echo ""

# 5. Créer un nouvel environnement virtuel
info "Création d'un nouvel environnement virtuel..."
uv venv
success "Environnement virtuel créé"
echo ""

# 6. Installer les dépendances
info "Installation des dépendances..."
info "Cela peut prendre quelques minutes..."
echo ""

uv sync --dev

success "Dépendances installées"
echo ""

# 7. Vérification de l'installation
info "Vérification de l'installation..."
echo ""

# Fonction de test d'import
test_import() {
    local module=$1
    local display_name=$2
    
    if uv run python -c "import $module" 2>/dev/null; then
        success "$display_name installé"
        return 0
    else
        error "$display_name manquant"
        return 1
    fi
}

# Tests des imports critiques
test_import "google.adk" "google-adk"
test_import "vertexai" "vertexai (google-cloud-aiplatform)"
test_import "langchain_google_vertexai" "langchain-google-vertexai"
test_import "langchain_google_community" "langchain-google-community"
test_import "langchain_core" "langchain-core"
test_import "opentelemetry" "opentelemetry"

echo ""

# 8. Test de l'application
info "Test de l'architecture multi-agent..."
if uv run python -c "from app.multi_agents import orchestrator_agent; print('✅ Architecture OK')" 2>/dev/null; then
    success "Architecture multi-agent validée"
else
    warning "Impossible de charger l'architecture (normal si GCP pas configuré)"
fi
echo ""

# 9. Résumé
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   ✅ Installation terminée !                                   ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

info "Packages installés :"
uv pip list | wc -l | xargs echo "  Total :"
echo ""

info "Prochaines étapes :"
echo "  1. Configurer GCP : ./setup_gcp.sh"
echo "  2. Tester l'architecture : python3 test_multi_agent.py"
echo "  3. Lancer le playground : make playground"
echo ""

info "Pour activer l'environnement manuellement :"
echo "  source .venv/bin/activate"
echo ""

success "Installation réussie ! 🎉"

