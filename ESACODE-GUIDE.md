# ESACODE-GUIDE.md

This file provides guidance  when working with code in this repository.

## Project Overview

Template Docker optimisé pour Odoo 19 Community Edition avec fonctionnalités avancées. Ce système utilise Docker Compose pour orchestrer un serveur Odoo, PostgreSQL, Redis et optionnellement Nginx.

## Architecture Optimisée

- **Web Service**: Odoo 19 server avec optimisations de performance (port 8069, 8072)
- **Database Service**: PostgreSQL 17 avec configuration pour la performance
- **Cache Service**: Redis 7 pour les sessions et le cache
- **Proxy Service**: Nginx avec SSL/TLS (optionnel, profil production)
- **Monitoring**: Health checks, logs structurés, métriques
- **Security**: Mots de passe sécurisés, filtres DB, permissions

## Essential Commands

### System Management
```bash
# Configuration initiale avec mots de passe sécurisés
./scripts/generate-passwords.sh

# Construction et démarrage optimisé
docker-compose up -d --build

# Démarrage des services
docker-compose start

# Arrêt des services
docker-compose stop

# Mode production avec Nginx
docker-compose --profile production up -d

# Nettoyage complet
docker-compose down -v --rmi all
```

### Development & Testing
```bash
# Tests système complets
./scripts/test-system.sh

# Tests avec base de données
./scripts/test-system.sh --full

# Création d'addon automatique
./scripts/create-addon.sh nom_addon "Description"

# Mode debug Odoo
docker-compose exec web odoo shell -d odoo_19_base

# Logs en temps réel
docker-compose logs -f web
```

### Backup & Restore
```bash
# Sauvegarde complète
./scripts/backup.sh [nom_sauvegarde]

# Restauration
./scripts/restore.sh nom_sauvegarde

# Lister les sauvegardes
ls backups/*_metadata.txt
```

### SSL/TLS Setup
```bash
# Certificats auto-signés (développement)
./scripts/generate-ssl.sh [domain]

# Let's Encrypt (production)
./nginx/ssl/letsencrypt-setup.sh domain.com email@domain.com
```

## Configuration Files

### Core Configuration
- `docker-compose.yml`: Orchestration avec Redis, health checks, logging
- `odoo/Dockerfile`: Image optimisée avec dépendances additionnelles
- `odoo/config/odoo.conf`: Configuration Odoo détaillée et documentée
- `.env`: Variables d'environnement sécurisées (générer avec script)

### Scripts Utilitaires
- `scripts/backup.sh`: Sauvegarde automatisée (DB + filestore + config)
- `scripts/restore.sh`: Restauration complète avec validation
- `scripts/create-addon.sh`: Génération d'addon avec structure complète
- `scripts/generate-passwords.sh`: Génération de mots de passe sécurisés
- `scripts/test-system.sh`: Tests système complets
- `scripts/generate-ssl.sh`: Génération de certificats SSL

### Production Setup
- `nginx/nginx.conf`: Configuration Nginx optimisée avec SSL et sécurité
- `nginx/ssl/`: Certificats SSL (auto-signés ou Let's Encrypt)

## Custom Addons Development

### Structure Recommandée
```
odoo/addons/
├── mon_addon/
│   ├── __manifest__.py
│   ├── models/
│   ├── views/
│   ├── controllers/
│   ├── static/
│   ├── security/
│   └── tests/
```

### Workflow de Développement
```bash
# 1. Créer un nouvel addon
./scripts/create-addon.sh mon_addon "Description"

# 2. Redémarrer Odoo
docker-compose restart web

# 3. Installer l'addon
docker-compose exec web odoo -d odoo_19_base -i mon_addon --stop-after-init

# 4. Tests
docker-compose exec web odoo -d odoo_19_base --test-enable -i mon_addon --stop-after-init
```

## Performance & Monitoring

### Health Checks
- Services avec health checks automatiques
- Monitoring des temps de réponse
- Vérification de l'état des volumes

### Optimization
- Redis pour cache et sessions
- Configuration mémoire optimisée
- Compression Gzip dans Nginx
- Logs rotatifs avec limite de taille

## Security Features

### Authentication
- Mots de passe générés automatiquement
- Filtres de base de données configurés
- Sessions sécurisées via Redis

### Network Security
- Réseau Docker isolé
- Ports de debug exposés uniquement si nécessaire
- Configuration SSL/TLS complète

### File Permissions
- Fichiers .env avec permissions 600
- Scripts exécutables avec bonnes permissions
- Volumes avec ownership correct

## Migration vers Odoo 19

### Préparation (Septembre 2025)
- Configuration compatible Odoo 19
- Structure prête pour les fonctionnalités IA
- Scripts de migration préparés
- Support du nouveau moteur de recherche

### Nouvelles Fonctionnalités Attendues
- IA intégrée avec agents personnels
- Moteur de recherche avancé
- Interface utilisateur modernisée
- Améliorations e-commerce et manufacturing

## Troubleshooting

### Commands Utiles
```bash
# Vérifier l'état des services
docker-compose ps

# Analyser les logs
docker-compose logs web | grep ERROR

# Tester la connectivité
curl -f http://localhost:8069/web/health

# Réinitialiser complètement
docker-compose down -v && docker-compose up -d --build
```

### Common Issues
- Port 8069 occupé: `sudo lsof -i :8069`
- Permissions fichiers: `sudo chown -R $USER:$USER ./`
- Base de données inaccessible: Vérifier les credentials dans .env
- Addons non détectés: Redémarrer le service web