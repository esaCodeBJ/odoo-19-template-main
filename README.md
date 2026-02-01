# 🚀 Template Odoo 19 Optimisé - Guide Complet

Un template Docker professionnel pour Odoo 19 Community Edition avec architecture moderne et outils de développement intégrés.

---

## 📋 Table des Matières

- [🎯 Vue d'ensemble](#-vue-densemble)
- [🏗️ Architecture](#-architecture)
- [⚡ Démarrage Rapide](#-démarrage-rapide)
- [🔧 Configuration Détaillée](#-configuration-détaillée)
- [📊 Services Inclus](#-services-inclus)
- [🛠️ Personnalisation](#-personnalisation)
- [📚 Guides d'Usage](#-guides-dusage)
- [🔒 Sécurité](#-sécurité)
- [🐛 Dépannage](#-dépannage)

---

## 🎯 Vue d'ensemble

Ce template fournit un environnement Odoo 19 complet avec :

### ✅ **Services Principaux**
- **Odoo 19** : Serveur principal avec optimisations performance
- **PostgreSQL 17** : Base de données avec configuration haute performance
- **Redis 7** : Cache pour accélération et gestion des sessions
- **pgAdmin** : Interface graphique pour gestion base de données

### ✅ **Services Optionnels**
- **Nginx** : Proxy inverse avec SSL pour production
- **AI Proxy** : Proxy pour APIs d'IA (OpenAI, Anthropic)

### ✅ **Outils Inclus**
- Scripts de sauvegarde/restauration automatisés
- Générateur d'addons avec templates
- Tests système complets
- Configuration SSL automatique
- Génération de mots de passe sécurisés

---

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Nginx        │    │   Odoo 19       │    │  PostgreSQL 17  │
│  (Production)   │───▶│   Serveur       │───▶│  Base Données   │
│   Port 80/443   │    │   Port 8069     │    │   Port 5432     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    pgAdmin      │    │     Redis       │    │   AI Proxy     │
│  Interface BD   │    │     Cache       │    │  (Optionnel)   │
│   Port 5050     │    │   Port 6379     │    │   Port 8080    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## ⚡ Démarrage Rapide

### 1️⃣ **Installation Basique**

```bash
# 1. Cloner le repository
git clone [URL_DU_REPO]
cd odoo-19-template-main

# 2. Générer les mots de passe sécurisés (RECOMMANDÉ)
./scripts/generate-passwords.sh

# 3. Démarrer les services essentiels
docker-compose up -d
```

### 2️⃣ **Accès aux Services**

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Odoo 19** | http://localhost:8069 | Voir `.env` pour admin password |
| **pgAdmin** | http://localhost:5050 | admin@example.com / admin_pgadmin_2025 |

### 3️⃣ **Configuration pgAdmin**

Dans pgAdmin, créer une connexion serveur :
- **Host** : `postgres_17_base_donnees`
- **Port** : `5432`
- **Database** : `odoo_19_base`
- **Username** : `odoo`
- **Password** : `odoo_secure_password_2025` (ou celui généré)

---

## 🔧 Configuration Détaillée

### 📝 **Modifier le Nom de la Base de Données**

1. **Dans docker-compose.yml :**
```yaml
environment:
  - POSTGRES_DB=mon_odoo_custom    # ← Changez ici
```

2. **Dans tous les scripts :**
```bash
# Rechercher et remplacer dans tous les fichiers
find . -name "*.sh" -exec sed -i 's/odoo_19_base/mon_odoo_custom/g' {} \;
```

3. **Redémarrer les services :**
```bash
docker-compose down
docker-compose up -d
```

### 🐳 **Noms des Containers**

Pour personnaliser les noms des containers, modifier dans `docker-compose.yml` :

```yaml
services:
  web:
    container_name: mon_odoo_serveur        # ← Personnalisez
  db:
    container_name: ma_base_donnees         # ← Personnalisez
  redis:
    container_name: mon_cache_redis         # ← Personnalisez
```

### 🔐 **Mots de Passe Sécurisés**

Le script `generate-passwords.sh` crée automatiquement :
- `.env` : Variables d'environnement avec mots de passe sécurisés
- `.env.example` : Template pour nouveaux environnements

**Structure du .env généré :**
```bash
# Base de données
POSTGRES_DB=odoo_19_base
POSTGRES_USER=odoo
POSTGRES_PASSWORD=mot_de_passe_securise_auto

# Odoo Admin
ODOO_ADMIN_PASSWD=admin_password_securise

# Redis
REDIS_PASSWORD=redis_password_securise
```

---

## 📊 Services Inclus

### 🌐 **Odoo 19 Serveur Principal**

**Container :** `odoo_19_serveur_principal`
**Ports :** 8069 (web), 8072 (longpolling)

**Fonctionnalités :**
- Mode développement activé (`--dev=reload,xml`)
- Optimisations mémoire configurées
- Health checks automatiques
- Logs rotatifs (10MB max, 5 fichiers)

**Volumes :**
- `./odoo/addons` → Vos addons personnalisés
- `./odoo/config` → Configuration Odoo
- `./logs` → Logs d'Odoo
- `./backups` → Sauvegardes

### 🗄️ **PostgreSQL 17 Base de Données**

**Container :** `postgres_17_base_donnees`
**Port :** 5432

**Pourquoi PostgreSQL ?**
- Base de données officielle recommandée par Odoo
- Performance optimisée pour les opérations Odoo
- Support complet des fonctionnalités avancées Odoo

**Configuration :**
- Encoding UTF-8 avec locale française
- Scripts d'initialisation automatiques
- Sauvegardes automatisées dans `./backups`

### ⚡ **Redis 7 Cache**

**Container :** `redis_cache_serveur`
**Port :** 6379

**À quoi sert Redis ?**
- **Sessions utilisateur** : Stockage rapide des sessions web
- **Cache applicatif** : Accélération des requêtes fréquentes
- **Performance** : Réduction de 30-50% des temps de réponse
- **Scalabilité** : Support multi-instances en production

**Configuration :**
- Mémoire max : 256MB
- Persistance activée (AOF)
- Policy LRU pour éviction automatique

### 🔍 **pgAdmin Interface**

**Container :** `pgadmin_interface_bd`
**Port :** 5050

**Fonctionnalités :**
- Interface graphique complète pour PostgreSQL
- Exploration des tables Odoo
- Requêtes SQL avancées
- Export/Import de données
- Monitoring des performances

### 🌐 **Nginx Proxy (Production)**

**Container :** `nginx_proxy_production`
**Ports :** 80, 443

**Activation :**
```bash
docker-compose --profile production up -d
```

**Fonctionnalités :**
- SSL/TLS automatique
- Compression Gzip
- Rate limiting (protection DDoS)
- Headers de sécurité
- Cache statique optimisé

### 🤖 **AI Proxy (Optionnel)**

**Container :** `ai_proxy_optionnel`

**Activation :**
```bash
docker-compose --profile ai-enabled up -d
```

**Usage :**
- Proxy pour APIs OpenAI/Anthropic
- Configuration avec clés API
- Monitoring des requêtes IA

---

## 🛠️ Personnalisation

### 🎨 **Mode de Démarrage**

**Développement (par défaut) :**
```bash
docker-compose up -d
```

**Production avec SSL :**
```bash
docker-compose --profile production up -d
```

**Avec fonctionnalités IA :**
```bash
docker-compose --profile ai-enabled up -d
```

### 📦 **Volumes Docker**

Les données persistent dans des volumes nommés :
- `postgres_data` : Données PostgreSQL
- `redis_data` : Cache Redis
- `odoo_filestore` : Fichiers uploadés Odoo
- `odoo_sessions` : Sessions utilisateurs
- `pgadmin_data` : Configuration pgAdmin

**Sauvegarde des volumes :**
```bash
./scripts/backup.sh ma_sauvegarde
```

**Restauration :**
```bash
./scripts/restore.sh ma_sauvegarde
```

### 🔧 **Configuration Odoo**

Le fichier `./odoo/config/odoo.conf` contient toute la configuration Odoo.

**Paramètres clés à personnaliser :**
```ini
# Base de données
dbfilter = ^odoo_19_base$           # Filtre DB (sécurité)
db_maxconn = 64                     # Connexions max BD

# Performance
workers = 4                         # Workers (0 = dev mode)
max_cron_threads = 2               # Threads cron
limit_memory_soft = 1073741824     # Limite mémoire soft (1GB)

# Sécurité
admin_passwd = mot_de_passe_admin  # Password master admin

# Modules
addons_path = /mnt/extra-addons    # Chemin addons custom
```

---

## 📚 Guides d'Usage

### 🚀 **Développement d'Addons**

**1. Créer un nouvel addon :**
```bash
./scripts/create-addon.sh mon_module "Description de mon module"
```

**2. Structure créée automatiquement :**
```
odoo/addons/mon_module/
├── __init__.py
├── __manifest__.py
├── models/
├── views/
├── static/
├── security/
└── tests/
```

**3. Installer l'addon :**
```bash
docker-compose exec web odoo -d odoo_19_base -i mon_module --stop-after-init
```

**4. Tests de l'addon :**
```bash
docker-compose exec web odoo -d odoo_19_base --test-enable -i mon_module --stop-after-init
```

### 💾 **Sauvegarde & Restauration**

**Sauvegarde complète :**
```bash
./scripts/backup.sh ma_sauvegarde_$(date +%Y%m%d)
```

**Contenu sauvegardé :**
- Base de données PostgreSQL (structure + données)
- Filestore Odoo (fichiers uploadés)
- Configuration (fichiers .conf)
- Métadonnées (version, date, etc.)

**Restauration :**
```bash
# Lister les sauvegardes disponibles
ls backups/*_metadata.txt

# Restaurer une sauvegarde
./scripts/restore.sh ma_sauvegarde_20240101
```

### 🔒 **Configuration SSL**

**Certificats auto-signés (développement) :**
```bash
./scripts/generate-ssl.sh localhost
```

**Let's Encrypt (production) :**
```bash
./nginx/ssl/letsencrypt-setup.sh mondomaine.com mon@email.com
```

### 🧪 **Tests Système**

**Tests complets :**
```bash
./scripts/test-system.sh
```

**Tests inclus :**
- Vérification Docker/Docker Compose
- État des containers
- Connectivité des ports
- Santé des services
- Performance mémoire/CPU

---

## 🔒 Sécurité

### 🛡️ **Bonnes Pratiques Intégrées**

1. **Mots de passe sécurisés** : Génération automatique 32 caractères
2. **Filtres base de données** : Protection contre accès non autorisé
3. **Sessions Redis** : Sécurisation des sessions utilisateur
4. **Headers sécurité** : Protection XSS, CSRF, clickjacking
5. **Rate limiting** : Protection DDoS sur login/API

### 🔐 **Configuration Production**

**Variables sensibles :**
```bash
# Dans .env (permissions 600)
chmod 600 .env

# Variables critiques
ODOO_ADMIN_PASSWD=password_super_securise
POSTGRES_PASSWORD=db_password_complexe
```

**Firewall recommandé :**
```bash
# Ouvrir uniquement les ports nécessaires
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw deny 5432/tcp   # PostgreSQL (interne seulement)
ufw deny 6379/tcp   # Redis (interne seulement)
```

---

## 🐛 Dépannage

### ❌ **Problèmes Courants**

**1. Port 8069 déjà utilisé :**
```bash
# Vérifier qui utilise le port
sudo lsof -i :8069
# Arrêter le service conflictuel ou changer le port
```

**2. Erreur de permissions :**
```bash
# Corriger les permissions
sudo chown -R $USER:$USER ./
chmod +x scripts/*.sh
```

**3. Base de données inaccessible :**
```bash
# Vérifier les logs PostgreSQL
docker-compose logs postgres_17_base_donnees

# Recréer la base si nécessaire
docker-compose exec postgres_17_base_donnees dropdb -U odoo odoo_19_base
docker-compose exec postgres_17_base_donnees createdb -U odoo odoo_19_base
```

**4. Addons non détectés :**
```bash
# Redémarrer Odoo
docker-compose restart odoo_19_serveur_principal

# Vérifier le chemin des addons
docker-compose exec web ls -la /mnt/extra-addons
```

### 🔧 **Commands de Debug**

**Logs en temps réel :**
```bash
# Tous les services
docker-compose logs -f

# Service spécifique
docker-compose logs -f odoo_19_serveur_principal
```

**Shell Odoo :**
```bash
docker-compose exec web odoo shell -d odoo_19_base
```

**Base de données :**
```bash
docker-compose exec postgres_17_base_donnees psql -U odoo -d odoo_19_base
```

**État complet du système :**
```bash
./scripts/test-system.sh --full
```

### 🆘 **Reset Complet**

En cas de problème majeur :
```bash
# ATTENTION: Supprime TOUTES les données
docker-compose down -v --rmi all
docker system prune -a --volumes

# Redémarrage propre
docker-compose up -d --build
```

---

## 📚 **Si vous ne voulez PAS utiliser certains services**

### 🚫 **Désactiver pgAdmin**

1. **Commenter dans docker-compose.yml :**
```yaml
  # pgadmin:
  #   image: dpage/pgadmin4:latest
  #   container_name: pgadmin_interface_bd
  #   # ... reste commenté
```

2. **Redémarrer :**
```bash
docker-compose down && docker-compose up -d
```

### 🚫 **Désactiver Redis**

1. **Commenter le service Redis :**
```yaml
  # redis:
  #   image: redis:7-alpine
  #   # ... reste commenté
```

2. **Modifier la config Odoo :**
```ini
# Dans odoo/config/odoo.conf
# Commenter la ligne Redis
# session_store = redis
```

### 🚫 **Désactiver les scripts de backup**

Les scripts sont optionnels, vous n'êtes pas obligé de les utiliser.

**Alternatives pour la sauvegarde :**
- Sauvegarde manuelle via pgAdmin
- Scripts personnalisés
- Solutions cloud (AWS RDS, etc.)

### 🚫 **Utiliser une autre base de données**

Pour utiliser votre propre PostgreSQL :

1. **Supprimer le service db :**
```yaml
# Commenter ou supprimer le service db
```

2. **Modifier les variables d'environnement :**
```yaml
environment:
  - POSTGRES_HOST=votre_serveur_db.com
  - POSTGRES_PORT=5432
  - POSTGRES_DB=votre_base
  - POSTGRES_USER=votre_user
  - POSTGRES_PASSWORD=votre_password
```


---

## 📞 **Support & Ressources**

### 📚 **Documentation Officielle**
- [Odoo 19 Developer Documentation](https://www.odoo.com/documentation/19.0/developer.html)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)

### 🛠️ **Outils Recommandés**
- **IDE** : VS Code avec extension Odoo
- **Git** : Gestion de version de vos addons
- **DBeaver** : Alternative desktop à pgAdmin

### 🎯 **Prochaines Étapes**
1. Parcourir les exemples d'addons dans `./odoo/addons/`
2. Consulter `ESACODE-GUIDE.md` pour les commandes spécifiques
3. Configurer votre environnement de développement
4. Créer votre premier addon avec `./scripts/create-addon.sh`

---

# Author

* [Expédit Sourou ALAGBE](https://github.com/esaCodeBJ)
* [esacode](https://github.com/esacodeorg)


**🎉 Bon développement avec Odoo 19 ! 🚀**