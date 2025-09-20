#!/bin/bash
# Script de vérification de santé pour Odoo

# Vérifier si Odoo répond sur le port 8069
if curl -f -s http://localhost:8069/web/health > /dev/null 2>&1; then
    echo "Odoo is healthy"
    exit 0
else
    # Fallback: vérifier si le processus Odoo est en cours d'exécution
    if pgrep -f "python.*odoo" > /dev/null; then
        echo "Odoo process is running but web interface might not be ready"
        exit 0
    else
        echo "Odoo is not running"
        exit 1
    fi
fi