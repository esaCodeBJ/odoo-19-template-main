#!/bin/bash
# Script de génération de mots de passe sécurisés pour Odoo 19

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE_FILE="$PROJECT_DIR/.env.example"

echo -e "${BLUE}🔐 Génération de mots de passe sécurisés pour Odoo 19${NC}"
echo -e "${YELLOW}📅 Date: $(date)${NC}"

# Fonction pour générer un mot de passe sécurisé
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-25
}

# Générer les mots de passe
DB_PASSWORD=$(generate_password)
ADMIN_PASSWORD=$(generate_password)
REDIS_PASSWORD=$(generate_password)

echo -e "\n${GREEN}🎯 Mots de passe générés:${NC}"
echo -e "${BLUE}📊 Base de données PostgreSQL: $DB_PASSWORD${NC}"
echo -e "${BLUE}👤 Admin Odoo: $ADMIN_PASSWORD${NC}"
echo -e "${BLUE}🔴 Redis: $REDIS_PASSWORD${NC}"

# Créer le fichier .env.example s'il n'existe pas
if [ ! -f "$ENV_EXAMPLE_FILE" ]; then
    cat > "$ENV_EXAMPLE_FILE" << 'EOF'
# Configuration Odoo 19 - Variables d'environnement
# Copiez ce fichier vers .env et personnalisez les valeurs

# =============================================================================
# BASE DE DONNÉES POSTGRESQL
# =============================================================================
POSTGRES_DB=odoo_19_base
POSTGRES_USER=odoo
POSTGRES_PASSWORD=changez_moi_mot_de_passe_securise

# =============================================================================
# ODOO
# =============================================================================
ODOO_ADMIN_PASSWD=changez_moi_admin_securise

# =============================================================================
# REDIS (CACHE)
# =============================================================================
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=changez_moi_redis_securise

# =============================================================================
# EMAIL / SMTP (OPTIONNEL)
# =============================================================================
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre_email@gmail.com
SMTP_PASSWORD=votre_mot_de_passe_app
EMAIL_FROM=odoo@votre-domaine.com

# =============================================================================
# DOMAINE ET SSL (PRODUCTION)
# =============================================================================
DOMAIN_NAME=votre-domaine.com
SSL_EMAIL=admin@votre-domaine.com

# =============================================================================
# DÉVELOPPEMENT
# =============================================================================
# Désactiver en production
DEBUG_MODE=True
DEV_MODE=reload,xml
LOG_LEVEL=info

# =============================================================================
# SÉCURITÉ (PRODUCTION)
# =============================================================================
# Activez en production
PROXY_MODE=False
LIST_DB=False
DBFILTER=^odoo_19_base$
EOF
    echo -e "${GREEN}✅ Fichier .env.example créé${NC}"
fi

# Créer ou mettre à jour le fichier .env
cat > "$ENV_FILE" << EOF
# Configuration Odoo 19 - Variables d'environnement
# Généré automatiquement le $(date)

# =============================================================================
# BASE DE DONNÉES POSTGRESQL
# =============================================================================
POSTGRES_DB=odoo_19_base
POSTGRES_USER=odoo
POSTGRES_PASSWORD=$DB_PASSWORD

# =============================================================================
# ODOO
# =============================================================================
ODOO_ADMIN_PASSWD=$ADMIN_PASSWORD

# =============================================================================
# REDIS (CACHE)
# =============================================================================
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD

# =============================================================================
# EMAIL / SMTP (OPTIONNEL)
# =============================================================================
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre_email@gmail.com
SMTP_PASSWORD=votre_mot_de_passe_app
EMAIL_FROM=odoo@votre-domaine.com

# =============================================================================
# DOMAINE ET SSL (PRODUCTION)
# =============================================================================
DOMAIN_NAME=localhost
SSL_EMAIL=admin@localhost

# =============================================================================
# DÉVELOPPEMENT
# =============================================================================
DEBUG_MODE=True
DEV_MODE=reload,xml
LOG_LEVEL=info

# =============================================================================
# SÉCURITÉ (PRODUCTION)
# =============================================================================
PROXY_MODE=False
LIST_DB=True
DBFILTER=^odoo_19_base$
EOF

echo -e "\n${GREEN}✅ Fichier .env créé avec succès !${NC}"
echo -e "${BLUE}📁 Emplacement: $ENV_FILE${NC}"

# Sécuriser le fichier .env
chmod 600 "$ENV_FILE"
echo -e "${GREEN}🔒 Permissions sécurisées appliquées au fichier .env${NC}"

# Créer un script de sauvegarde des mots de passe
BACKUP_FILE="$PROJECT_DIR/backups/passwords_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p "$(dirname "$BACKUP_FILE")"

cat > "$BACKUP_FILE" << EOF
Mots de passe Odoo 19 - $(date)
===============================

Base de données PostgreSQL:
   Utilisateur: odoo
   Mot de passe: $DB_PASSWORD

Admin Odoo:
   Utilisateur: admin
   Mot de passe: $ADMIN_PASSWORD

Redis:
   Mot de passe: $REDIS_PASSWORD

IMPORTANT:
- Conservez ces mots de passe en lieu sûr
- Changez le mot de passe admin après la première connexion
- En production, utilisez des certificats SSL
- Configurez la sauvegarde automatique

URL d'accès: http://localhost:8069
Base de données: odoo_19_base
EOF

chmod 600 "$BACKUP_FILE"
echo -e "${GREEN}💾 Sauvegarde des mots de passe: $BACKUP_FILE${NC}"

echo -e "\n${YELLOW}⚠️ IMPORTANT - SÉCURITÉ:${NC}"
echo -e "${YELLOW}   1. Conservez ces mots de passe en lieu sûr${NC}"
echo -e "${YELLOW}   2. Changez le mot de passe admin après la première connexion${NC}"
echo -e "${YELLOW}   3. Ne commitez JAMAIS le fichier .env dans Git${NC}"
echo -e "${YELLOW}   4. En production, utilisez des certificats SSL${NC}"

echo -e "\n${BLUE}🚀 Prochaines étapes:${NC}"
echo -e "${BLUE}   1. Vérifiez les paramètres dans .env${NC}"
echo -e "${BLUE}   2. Configurez l'email si nécessaire${NC}"
echo -e "${BLUE}   3. Lancez Odoo: docker-compose up -d --build${NC}"
echo -e "${BLUE}   4. Accédez à http://localhost:8069${NC}"
echo -e "${BLUE}   5. Connectez-vous avec admin / $ADMIN_PASSWORD${NC}"

# Générer également un mot de passe pour Nginx (production)
NGINX_PASSWORD=$(generate_password)
echo -e "\n${BLUE}💡 Bonus - Mot de passe Nginx (htpasswd): $NGINX_PASSWORD${NC}"

# Créer la configuration htpasswd pour Nginx
if command -v htpasswd &> /dev/null; then
    echo "admin:$(openssl passwd -apr1 "$NGINX_PASSWORD")" > "$PROJECT_DIR/nginx/htpasswd" 2>/dev/null || true
    echo -e "${GREEN}🔐 Fichier htpasswd créé pour Nginx${NC}"
fi

echo -e "\n${GREEN}🎉 Configuration terminée !${NC}"