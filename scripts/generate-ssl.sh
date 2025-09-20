#!/bin/bash
# Script de génération de certificats SSL auto-signés pour Odoo 19
# Usage: ./generate-ssl.sh [domain]

set -e

DOMAIN="${1:-localhost}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSL_DIR="$PROJECT_DIR/nginx/ssl"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Génération de certificats SSL pour Odoo 19${NC}"
echo -e "${YELLOW}📅 Date: $(date)${NC}"
echo -e "${YELLOW}🌐 Domaine: $DOMAIN${NC}"

# Créer le répertoire SSL
mkdir -p "$SSL_DIR"

echo -e "\n${BLUE}📋 Génération de la clé privée...${NC}"
# Générer la clé privée
openssl genrsa -out "$SSL_DIR/odoo.key" 2048

echo -e "${GREEN}✅ Clé privée générée${NC}"

echo -e "\n${BLUE}📋 Génération du certificat...${NC}"
# Créer le fichier de configuration pour le certificat
cat > "$SSL_DIR/openssl.cnf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = FR
ST = France
L = Paris
O = Odoo 19 Development
OU = IT Department
CN = $DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = localhost
DNS.3 = *.${DOMAIN}
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Générer le certificat auto-signé
openssl req -new -x509 -key "$SSL_DIR/odoo.key" -out "$SSL_DIR/odoo.crt" -days 365 -config "$SSL_DIR/openssl.cnf" -extensions v3_req

echo -e "${GREEN}✅ Certificat généré${NC}"

# Sécuriser les fichiers
chmod 600 "$SSL_DIR/odoo.key"
chmod 644 "$SSL_DIR/odoo.crt"

echo -e "\n${BLUE}🔍 Informations du certificat:${NC}"
openssl x509 -in "$SSL_DIR/odoo.crt" -text -noout | grep -E "(Subject:|Not Before|Not After|DNS:|IP Address:)"

echo -e "\n${GREEN}🎉 Certificats SSL générés avec succès !${NC}"
echo -e "${BLUE}📁 Emplacement:${NC}"
echo -e "${BLUE}   - Clé privée: $SSL_DIR/odoo.key${NC}"
echo -e "${BLUE}   - Certificat: $SSL_DIR/odoo.crt${NC}"

echo -e "\n${YELLOW}⚠️ IMPORTANT - Certificats auto-signés:${NC}"
echo -e "${YELLOW}   1. Ces certificats sont pour le développement uniquement${NC}"
echo -e "${YELLOW}   2. Les navigateurs afficheront un avertissement de sécurité${NC}"
echo -e "${YELLOW}   3. Pour la production, utilisez Let's Encrypt ou un CA reconnu${NC}"

echo -e "\n${BLUE}🚀 Prochaines étapes:${NC}"
echo -e "${BLUE}   1. Démarrez avec Nginx: docker-compose --profile production up -d${NC}"
echo -e "${BLUE}   2. Accédez à https://$DOMAIN${NC}"
echo -e "${BLUE}   3. Acceptez l'exception de sécurité dans le navigateur${NC}"

# Créer un script d'installation du certificat dans le système (optionnel)
cat > "$SSL_DIR/install-cert.sh" << 'EOF'
#!/bin/bash
# Script d'installation du certificat dans le magasin système (Linux/macOS)

CERT_FILE="$(dirname "$0")/odoo.crt"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v update-ca-certificates &> /dev/null; then
        sudo cp "$CERT_FILE" /usr/local/share/ca-certificates/odoo.crt
        sudo update-ca-certificates
        echo "Certificat installé pour Linux"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_FILE"
    echo "Certificat installé pour macOS"
else
    echo "OS non supporté pour l'installation automatique"
    echo "Installez manuellement le certificat: $CERT_FILE"
fi
EOF

chmod +x "$SSL_DIR/install-cert.sh"

echo -e "\n${BLUE}💡 Pour éviter les avertissements de sécurité:${NC}"
echo -e "${BLUE}   Exécutez: $SSL_DIR/install-cert.sh${NC}"

# Générer également un certificat pour Let's Encrypt (template)
cat > "$SSL_DIR/letsencrypt-setup.sh" << EOF
#!/bin/bash
# Script de configuration Let's Encrypt pour production
# Usage: ./letsencrypt-setup.sh votre-domaine.com email@domaine.com

DOMAIN="\$1"
EMAIL="\$2"

if [ -z "\$DOMAIN" ] || [ -z "\$EMAIL" ]; then
    echo "Usage: \$0 domaine.com email@domaine.com"
    exit 1
fi

# Installer Certbot
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Obtenir le certificat
sudo certbot --nginx -d "\$DOMAIN" --email "\$EMAIL" --agree-tos --non-interactive

# Configurer le renouvellement automatique
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

echo "Certificat Let's Encrypt configuré pour \$DOMAIN"
EOF

chmod +x "$SSL_DIR/letsencrypt-setup.sh"

echo -e "\n${BLUE}🌐 Pour un certificat Let's Encrypt en production:${NC}"
echo -e "${BLUE}   Exécutez: $SSL_DIR/letsencrypt-setup.sh votre-domaine.com email@domaine.com${NC}"

# Nettoyer le fichier de configuration temporaire
rm -f "$SSL_DIR/openssl.cnf"

echo -e "\n${GREEN}✨ Configuration SSL terminée !${NC}"