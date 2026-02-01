#!/bin/bash
# Script de restauration pour Odoo 19
# Usage: ./restore.sh nom_de_la_sauvegarde

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backups"
BACKUP_NAME="$1"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -z "$BACKUP_NAME" ]; then
    echo -e "${RED}❌ Usage: ./restore.sh nom_de_la_sauvegarde${NC}"
    echo -e "${BLUE}📋 Sauvegardes disponibles:${NC}"
    ls -1 "$BACKUP_DIR"/*_metadata.txt 2>/dev/null | sed 's/_metadata.txt//' | xargs -I {} basename {} || echo "Aucune sauvegarde trouvée"
    exit 1
fi

echo -e "${BLUE}🔄 Démarrage de la restauration Odoo 19${NC}"
echo -e "${YELLOW}📅 Date: $(date)${NC}"
echo -e "${YELLOW}📁 Sauvegarde: $BACKUP_NAME${NC}"

# Vérifier que les fichiers de sauvegarde existent
if [ ! -f "$BACKUP_DIR/${BACKUP_NAME}_database.sql.gz" ]; then
    echo -e "${RED}❌ Fichier de sauvegarde non trouvé: ${BACKUP_NAME}_database.sql.gz${NC}"
    exit 1
fi

# Afficher les informations de la sauvegarde
if [ -f "$BACKUP_DIR/${BACKUP_NAME}_metadata.txt" ]; then
    echo -e "${BLUE}📋 Informations de la sauvegarde:${NC}"
    cat "$BACKUP_DIR/${BACKUP_NAME}_metadata.txt"
    echo ""
fi

# Demander confirmation
echo -e "${YELLOW}⚠️ ATTENTION: Cette opération va :${NC}"
echo -e "${YELLOW}   - Supprimer la base de données actuelle${NC}"
echo -e "${YELLOW}   - Restaurer les données de sauvegarde${NC}"
echo -e "${YELLOW}   - Remplacer le filestore${NC}"
echo ""
read -p "Êtes-vous sûr de vouloir continuer ? (oui/non): " confirm

if [ "$confirm" != "oui" ]; then
    echo -e "${BLUE}❌ Restauration annulée${NC}"
    exit 0
fi

cd "$PROJECT_DIR"

# Arrêter Odoo mais garder la base de données
echo -e "${BLUE}⏸️ Arrêt d'Odoo...${NC}"
docker-compose stop web

echo -e "${BLUE}🗑️ Suppression de la base de données actuelle...${NC}"
# Supprimer la base de données existante
docker-compose exec -T db dropdb -U odoo --if-exists odoo_19_base

echo -e "${BLUE}🆕 Création d'une nouvelle base de données...${NC}"
# Créer une nouvelle base de données
docker-compose exec -T db createdb -U odoo odoo_19_base

echo -e "${BLUE}📦 Restauration de la base de données...${NC}"
# Restaurer la base de données
gunzip -c "$BACKUP_DIR/${BACKUP_NAME}_database.sql.gz" | docker-compose exec -T db psql -U odoo -d odoo_19_base

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Base de données restaurée${NC}"
else
    echo -e "${RED}❌ Erreur lors de la restauration de la base de données${NC}"
    exit 1
fi

# Restaurer le filestore si disponible
if [ -f "$BACKUP_DIR/${BACKUP_NAME}_filestore.tar.gz" ]; then
    echo -e "${BLUE}📁 Restauration du filestore...${NC}"

    # Supprimer l'ancien filestore
    docker volume rm odoo-19-optimized_odoo_filestore 2>/dev/null || true

    # Créer un nouveau volume
    docker volume create odoo-19-optimized_odoo_filestore

    # Restaurer le filestore
    docker run --rm -v odoo-19-optimized_odoo_filestore:/target -v "$BACKUP_DIR":/backup alpine tar xzf "/backup/${BACKUP_NAME}_filestore.tar.gz" -C /target

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Filestore restauré${NC}"
    else
        echo -e "${RED}❌ Erreur lors de la restauration du filestore${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️ Aucun filestore trouvé dans la sauvegarde${NC}"
fi

# Restaurer la configuration si disponible
if [ -f "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz" ]; then
    echo -e "${BLUE}⚙️ Restauration de la configuration...${NC}"

    # Sauvegarder la configuration actuelle
    cp -r "$PROJECT_DIR/odoo/config" "$PROJECT_DIR/odoo/config.backup.$(date +%s)" 2>/dev/null || true

    # Restaurer la configuration
    tar xzf "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz" -C "$PROJECT_DIR"

    echo -e "${GREEN}✅ Configuration restaurée${NC}"
else
    echo -e "${YELLOW}⚠️ Aucune configuration trouvée dans la sauvegarde${NC}"
fi

# Restaurer les addons si disponibles
if [ -f "$BACKUP_DIR/${BACKUP_NAME}_addons.tar.gz" ]; then
    echo -e "${BLUE}📋 Restauration des addons...${NC}"

    # Sauvegarder les addons actuels
    if [ -d "$PROJECT_DIR/odoo/addons" ]; then
        mv "$PROJECT_DIR/odoo/addons" "$PROJECT_DIR/odoo/addons.backup.$(date +%s)" 2>/dev/null || true
    fi

    # Restaurer les addons
    tar xzf "$BACKUP_DIR/${BACKUP_NAME}_addons.tar.gz" -C "$PROJECT_DIR"

    echo -e "${GREEN}✅ Addons restaurés${NC}"
else
    echo -e "${YELLOW}⚠️ Aucun addon trouvé dans la sauvegarde${NC}"
fi

echo -e "${BLUE}🚀 Redémarrage d'Odoo...${NC}"
# Redémarrer tous les services
docker-compose up -d

# Attendre que les services soient prêts
echo -e "${BLUE}⏳ Attente du démarrage des services...${NC}"
sleep 10

# Vérifier que tout fonctionne
echo -e "${BLUE}🔍 Vérification de l'état des services...${NC}"
docker-compose ps

# Test de connexion à Odoo
echo -e "${BLUE}🌐 Test de connexion à Odoo...${NC}"
for i in {1..30}; do
    if curl -f -s http://localhost:8069/web/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Odoo est accessible sur http://localhost:8069${NC}"
        break
    else
        echo -e "${YELLOW}⏳ Attente d'Odoo... ($i/30)${NC}"
        sleep 2
    fi
done

echo -e "\n${GREEN}🎉 Restauration terminée avec succès !${NC}"
echo -e "${BLUE}🌐 Accédez à Odoo: http://localhost:8069${NC}"
echo -e "${BLUE}📊 Base de données: odoo_19_base${NC}"
echo -e "${BLUE}👤 Utilisez vos identifiants d'origine pour vous connecter${NC}"

echo -e "\n${YELLOW}💡 Notes importantes:${NC}"
echo -e "${YELLOW}   - Vérifiez que tous vos addons fonctionnent correctement${NC}"
echo -e "${YELLOW}   - Consultez les logs en cas de problème: docker-compose logs web${NC}"
echo -e "${YELLOW}   - Les configurations sauvegardées ont été restaurées${NC}"