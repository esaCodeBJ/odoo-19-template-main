#!/bin/bash
# Script de sauvegarde pour Odoo 19
# Usage: ./backup.sh [nom_de_la_sauvegarde]

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="${1:-odoo_backup_$DATE}"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Démarrage de la sauvegarde Odoo 19${NC}"
echo -e "${YELLOW}📅 Date: $(date)${NC}"
echo -e "${YELLOW}📁 Nom: $BACKUP_NAME${NC}"

# Créer le répertoire de sauvegarde s'il n'existe pas
mkdir -p "$BACKUP_DIR"

# Vérifier que Docker Compose est disponible
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose n'est pas installé${NC}"
    exit 1
fi

# Vérifier que les conteneurs sont en cours d'exécution
if ! docker-compose ps | grep -q "odoo_19_serveur_principal.*Up"; then
    echo -e "${RED}❌ Le conteneur Odoo n'est pas en cours d'exécution${NC}"
    echo -e "${YELLOW}💡 Démarrez-le avec: docker-compose up -d${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

echo -e "${BLUE}📦 Sauvegarde de la base de données...${NC}"
# Sauvegarde de la base de données PostgreSQL
docker-compose exec -T db pg_dump -U odoo -d odoo_19_base | gzip > "$BACKUP_DIR/${BACKUP_NAME}_database.sql.gz"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Base de données sauvegardée${NC}"
else
    echo -e "${RED}❌ Erreur lors de la sauvegarde de la base de données${NC}"
    exit 1
fi

echo -e "${BLUE}📁 Sauvegarde des fichiers filestore...${NC}"
# Sauvegarde du filestore (fichiers uploadés)
docker run --rm -v odoo-19-optimized_odoo_filestore:/source -v "$BACKUP_DIR":/backup alpine tar czf "/backup/${BACKUP_NAME}_filestore.tar.gz" -C /source .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Filestore sauvegardé${NC}"
else
    echo -e "${RED}❌ Erreur lors de la sauvegarde du filestore${NC}"
    exit 1
fi

echo -e "${BLUE}⚙️ Sauvegarde de la configuration...${NC}"
# Sauvegarde de la configuration
tar czf "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz" -C "$PROJECT_DIR" \
    odoo/config/ \
    docker-compose.yml \
    .env 2>/dev/null || true

echo -e "${GREEN}✅ Configuration sauvegardée${NC}"

echo -e "${BLUE}📋 Sauvegarde des addons personnalisés...${NC}"
# Sauvegarde des addons personnalisés
if [ -d "$PROJECT_DIR/odoo/addons" ] && [ "$(ls -A "$PROJECT_DIR/odoo/addons")" ]; then
    tar czf "$BACKUP_DIR/${BACKUP_NAME}_addons.tar.gz" -C "$PROJECT_DIR" odoo/addons/
    echo -e "${GREEN}✅ Addons sauvegardés${NC}"
else
    echo -e "${YELLOW}⚠️ Aucun addon personnalisé trouvé${NC}"
fi

# Créer un fichier de métadonnées
cat > "$BACKUP_DIR/${BACKUP_NAME}_metadata.txt" << EOF
Sauvegarde Odoo 19
==================
Date: $(date)
Nom: $BACKUP_NAME
Version Odoo: 19.0
PostgreSQL: $(docker-compose exec -T db psql -U odoo -d odoo_19_base -t -c "SELECT version();" | head -1 | xargs)

Fichiers inclus:
- ${BACKUP_NAME}_database.sql.gz (Base de données)
- ${BACKUP_NAME}_filestore.tar.gz (Fichiers uploadés)
- ${BACKUP_NAME}_config.tar.gz (Configuration)
- ${BACKUP_NAME}_addons.tar.gz (Addons personnalisés)

Pour restaurer:
./scripts/restore.sh $BACKUP_NAME
EOF

# Afficher les informations de la sauvegarde
echo -e "\n${GREEN}🎉 Sauvegarde terminée avec succès !${NC}"
echo -e "${BLUE}📍 Emplacement: $BACKUP_DIR${NC}"
echo -e "${BLUE}📊 Taille des fichiers:${NC}"
ls -lh "$BACKUP_DIR"/${BACKUP_NAME}_* | awk '{print "   " $9 " : " $5}'

# Calculer la taille totale
TOTAL_SIZE=$(du -sh "$BACKUP_DIR"/${BACKUP_NAME}_* | awk '{total+=$1} END {print total "K"}')
echo -e "${BLUE}📦 Taille totale: $TOTAL_SIZE${NC}"

# Nettoyage automatique (garder seulement les 7 dernières sauvegardes)
echo -e "\n${YELLOW}🧹 Nettoyage des anciennes sauvegardes...${NC}"
cd "$BACKUP_DIR"
ls -t odoo_backup_*_metadata.txt 2>/dev/null | tail -n +8 | while read metadata_file; do
    backup_prefix=$(basename "$metadata_file" "_metadata.txt")
    echo -e "${YELLOW}🗑️ Suppression de: $backup_prefix${NC}"
    rm -f "${backup_prefix}"_*
done

echo -e "\n${GREEN}✨ Processus de sauvegarde terminé !${NC}"
echo -e "${BLUE}💡 Pour restaurer cette sauvegarde: ./scripts/restore.sh $BACKUP_NAME${NC}"