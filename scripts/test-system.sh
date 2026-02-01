#!/bin/bash
# Script de test du système Odoo 19
# Usage: ./test-system.sh

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}🧪 Tests Système Odoo 19${NC}"
echo -e "${YELLOW}📅 Date: $(date)${NC}"

# Compteurs
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Fonction pour exécuter un test
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "\n${BLUE}🔍 Test: $test_name${NC}"

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Fonction pour tester la connectivité
test_connectivity() {
    local service="$1"
    local url="$2"
    local timeout="${3:-10}"

    curl -f -s --max-time "$timeout" "$url" > /dev/null 2>&1
}

# Fonction pour tester un port
test_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-5}"

    timeout "$timeout" bash -c "</dev/tcp/$host/$port" > /dev/null 2>&1
}

echo -e "\n${YELLOW}🐳 Tests Docker${NC}"

# Test Docker
run_test "Docker installé" "command -v docker"
run_test "Docker Compose installé" "command -v docker-compose"
run_test "Docker daemon en cours" "docker info"

echo -e "\n${YELLOW}📦 Tests Conteneurs${NC}"

# Tests des conteneurs
run_test "Conteneur Odoo en cours" "docker-compose ps | grep odoo_19_serveur_principal | grep Up"
run_test "Conteneur PostgreSQL en cours" "docker-compose ps | grep postgres_17_base_donnees | grep Up"
run_test "Conteneur Redis en cours" "docker-compose ps | grep redis_cache_serveur | grep Up"

echo -e "\n${YELLOW}🌐 Tests Connectivité${NC}"

# Tests de connectivité
run_test "Port 8069 accessible" "test_port localhost 8069"
run_test "Port 5432 accessible" "test_port localhost 5432"
run_test "Port 6379 accessible" "test_port localhost 6379"

echo -e "\n${YELLOW}🔍 Tests Services${NC}"

# Tests des services
run_test "Interface web Odoo" "test_connectivity 'Odoo Web' 'http://localhost:8069/web/health'"
run_test "Base de données PostgreSQL" "docker-compose exec -T db pg_isready -U odoo -d odoo_19_base"
run_test "Service Redis" "docker-compose exec -T redis redis-cli ping | grep -q PONG"

echo -e "\n${YELLOW}📊 Tests Base de Données${NC}"

# Tests base de données
run_test "Connexion DB Odoo" "docker-compose exec -T db psql -U odoo -d odoo_19_base -c 'SELECT 1;'"
run_test "Tables Odoo présentes" "docker-compose exec -T db psql -U odoo -d odoo_19_base -c \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';\" | grep -q '[1-9]'"

echo -e "\n${YELLOW}💾 Tests Volumes${NC}"

# Tests volumes
run_test "Volume PostgreSQL" "docker volume inspect odoo-19-optimized_postgres_data"
run_test "Volume Redis" "docker volume inspect odoo-19-optimized_redis_data"
run_test "Volume Filestore" "docker volume inspect odoo-19-optimized_odoo_filestore"

echo -e "\n${YELLOW}📁 Tests Fichiers${NC}"

# Tests fichiers
run_test "Configuration Odoo" "[ -f '$PROJECT_DIR/odoo/config/odoo.conf' ]"
run_test "Docker Compose" "[ -f '$PROJECT_DIR/docker-compose.yml' ]"
run_test "Scripts présents" "[ -d '$PROJECT_DIR/scripts' ]"
run_test "Répertoire addons" "[ -d '$PROJECT_DIR/odoo/addons' ]"

echo -e "\n${YELLOW}🔒 Tests Sécurité${NC}"

# Tests sécurité basiques
run_test "Fichier .env protégé" "[ -f '$PROJECT_DIR/.env' ] && [ \$(stat -c '%a' '$PROJECT_DIR/.env') -eq 600 ]"
run_test "Pas de mot de passe par défaut" "! grep -q 'odoo' '$PROJECT_DIR/.env' 2>/dev/null || ! grep -q 'admin' '$PROJECT_DIR/.env' 2>/dev/null"

echo -e "\n${YELLOW}🚀 Tests Performance${NC}"

# Tests performance
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:8069/web/health 2>/dev/null || echo "999")
if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l 2>/dev/null || echo 0) )); then
    run_test "Temps de réponse < 2s ($RESPONSE_TIME s)" "true"
else
    run_test "Temps de réponse < 2s ($RESPONSE_TIME s)" "false"
fi

# Test mémoire
MEMORY_USAGE=$(docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}" | grep odoo_19_serveur_principal | awk '{print $2}' | cut -d'/' -f1 || echo "0")
echo -e "${BLUE}💾 Utilisation mémoire Odoo: $MEMORY_USAGE${NC}"

echo -e "\n${YELLOW}🧪 Tests Fonctionnels${NC}"

# Tests fonctionnels basiques
run_test "API JSON-RPC" "curl -s -X POST http://localhost:8069/jsonrpc -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"call\",\"params\":{\"service\":\"db\",\"method\":\"server_version\"},\"id\":1}' | grep -q version"

# Test de création de base de données (optionnel)
if [ "$1" = "--full" ]; then
    echo -e "\n${YELLOW}🔬 Tests Complets (Base de données)${NC}"

    TEST_DB="test_$(date +%s)"
    run_test "Création DB test" "docker-compose exec -T db createdb -U odoo $TEST_DB"
    run_test "Suppression DB test" "docker-compose exec -T db dropdb -U odoo $TEST_DB"
fi

echo -e "\n${BLUE}📋 RÉSULTATS DES TESTS${NC}"
echo -e "${BLUE}===================${NC}"
echo -e "${GREEN}✅ Tests réussis: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests échoués: $TESTS_FAILED${NC}"
echo -e "${BLUE}📊 Total: $TESTS_TOTAL${NC}"

PASS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))
echo -e "${BLUE}📈 Taux de réussite: $PASS_RATE%${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Tous les tests sont passés ! Votre installation Odoo 19 est fonctionnelle.${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️ Certains tests ont échoué. Vérifiez les logs:${NC}"
    echo -e "${YELLOW}   docker-compose logs web${NC}"
    echo -e "${YELLOW}   docker-compose logs db${NC}"
    echo -e "${YELLOW}   docker-compose logs redis${NC}"
    exit 1
fi