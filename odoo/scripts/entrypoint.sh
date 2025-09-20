#!/bin/bash
set -e

# Script d'initialisation pour Odoo
echo "🚀 Démarrage d'Odoo 19 optimisé..."

# Vérifier les variables d'environnement
if [ -z "$POSTGRES_HOST" ]; then
    export POSTGRES_HOST="db"
fi

if [ -z "$POSTGRES_PORT" ]; then
    export POSTGRES_PORT="5432"
fi

if [ -z "$POSTGRES_USER" ]; then
    export POSTGRES_USER="odoo"
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD="odoo"
fi

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de la base de données PostgreSQL..."
while ! pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -q; do
    sleep 2
    echo "En attente de PostgreSQL..."
done
echo "✅ Base de données PostgreSQL prête !"

# Créer la base de données si elle n'existe pas
echo "🔧 Vérification de la base de données..."
if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"; then
    echo "📦 Création de la base de données $POSTGRES_DB..."
    PGPASSWORD="$POSTGRES_PASSWORD" createdb -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$POSTGRES_DB"
fi

# Afficher les informations de démarrage
echo "📋 Configuration Odoo:"
echo "   - Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "   - Database: $POSTGRES_DB"
echo "   - User: $POSTGRES_USER"
echo "   - Addons path: /mnt/extra-addons"

# Démarrer Odoo avec les arguments passés
echo "🎯 Lancement d'Odoo..."
exec "$@"