# 📦 Addons Personnalisés Odoo 19

Ce répertoire contient vos addons personnalisés pour Odoo 19.

## 🏗️ Structure Recommandée

```
odoo/addons/
├── 📁 mon_addon/                    # Votre addon principal
│   ├── 📄 __init__.py              # Initialisation Python
│   ├── 📄 __manifest__.py          # Manifeste de l'addon
│   ├── 📄 README.md                # Documentation
│   ├── 📁 models/                  # Modèles de données
│   │   ├── 📄 __init__.py
│   │   └── 📄 mon_model.py
│   ├── 📁 views/                   # Vues XML
│   │   ├── 📄 mon_addon_views.xml
│   │   └── 📄 menu.xml
│   ├── 📁 controllers/             # Contrôleurs web
│   │   ├── 📄 __init__.py
│   │   └── 📄 main.py
│   ├── 📁 static/                  # Ressources statiques
│   │   ├── 📁 description/         # Icône et description
│   │   │   ├── 📄 icon.png         # Icône 128x128px
│   │   │   └── 📄 index.html       # Page de description
│   │   └── 📁 src/                 # Sources frontend
│   │       ├── 📁 css/
│   │       ├── 📁 js/
│   │       └── 📁 xml/
│   ├── 📁 security/                # Sécurité et droits d'accès
│   │   └── 📄 ir.model.access.csv
│   ├── 📁 data/                    # Données par défaut
│   ├── 📁 demo/                    # Données de démonstration
│   ├── 📁 wizard/                  # Assistants
│   ├── 📁 report/                  # Rapports
│   └── 📁 tests/                   # Tests unitaires
└── 📁 autre_addon/                 # Autres addons
```

## 🚀 Création Rapide d'un Addon

Utilisez le script de génération automatique :

```bash
# Créer un nouvel addon
./scripts/create-addon.sh mon_addon "Description de mon addon"

# Exemple concret
./scripts/create-addon.sh gestion_taches "Gestion des tâches quotidiennes"
```

## 📋 Checklist pour Nouvel Addon

### ✅ Fichiers Obligatoires
- [ ] `__init__.py` - Initialisation Python
- [ ] `__manifest__.py` - Métadonnées de l'addon
- [ ] `models/__init__.py` - Import des modèles
- [ ] `views/` - Au moins une vue
- [ ] `security/ir.model.access.csv` - Droits d'accès

### ✅ Fichiers Recommandés
- [ ] `README.md` - Documentation
- [ ] `static/description/icon.png` - Icône de l'addon
- [ ] `data/` - Données par défaut
- [ ] `demo/` - Données de démonstration
- [ ] `tests/` - Tests unitaires

## 🛠️ Exemple de Manifeste (__manifest__.py)

```python
{
    'name': 'Mon Addon Génial',
    'version': '19.0.1.0.0',
    'category': 'Custom',
    'summary': 'Résumé court de l\'addon',
    'description': '''
        Description longue de votre addon.

        Fonctionnalités:
        - Fonctionnalité 1
        - Fonctionnalité 2
        - Fonctionnalité 3
    ''',
    'author': 'Votre Nom',
    'website': 'https://votre-site.com',
    'license': 'LGPL-3',
    'depends': ['base', 'web'],
    'data': [
        'security/ir.model.access.csv',
        'views/mon_addon_views.xml',
        'data/mon_addon_data.xml',
    ],
    'demo': [
        'demo/mon_addon_demo.xml',
    ],
    'qweb': [
        'static/src/xml/templates.xml',
    ],
    'installable': True,
    'auto_install': False,
    'application': True,  # True si c'est une application principale
}
```

## 🔧 Commandes Utiles

### Installation et Mise à Jour
```bash
# Redémarrer Odoo pour détecter les nouveaux addons
docker-compose restart web

# Installer un addon
docker-compose exec web odoo -d odoo_19_base -i mon_addon --stop-after-init

# Mettre à jour un addon
docker-compose exec web odoo -d odoo_19_base -u mon_addon --stop-after-init

# Installer avec données de démo
docker-compose exec web odoo -d odoo_19_base -i mon_addon --without-demo=False --stop-after-init
```

### Tests et Debug
```bash
# Lancer les tests d'un addon
docker-compose exec web odoo -d odoo_19_base --test-enable -i mon_addon --stop-after-init

# Mode debug
docker-compose exec web odoo -d odoo_19_base --dev=reload,xml

# Shell Odoo pour debug
docker-compose exec web odoo shell -d odoo_19_base
```

### Logs
```bash
# Voir les logs Odoo
docker-compose logs -f web

# Logs spécifiques à un addon
docker-compose logs web | grep mon_addon
```

## 🎨 Bonnes Pratiques

### 📝 Nommage
- **Addons** : `snake_case` (ex: `gestion_stock`)
- **Modèles** : `snake_case` avec préfixe addon (ex: `gestion_stock.produit`)
- **Champs** : `snake_case` (ex: `date_creation`)
- **Méthodes** : `snake_case` (ex: `calculer_total`)

### 🏗️ Architecture
- Un addon = une fonctionnalité métier
- Modèles dans `models/`
- Vues dans `views/`
- Logique métier dans les modèles
- Pas de logique dans les contrôleurs

### 🔒 Sécurité
- Toujours définir les droits d'accès
- Utiliser `sudo()` avec précaution
- Valider les données d'entrée
- Échapper les données dans les vues

### 📊 Performance
- Utiliser les domaines pour filtrer
- Éviter les boucles Python sur de gros datasets
- Préférer les requêtes SQL optimisées
- Utiliser le cache quand approprié

## 🔄 Migration vers Odoo 19

### Préparation
Vos addons sont déjà préparés pour Odoo 19 grâce à :

- ✅ Structure de fichiers compatible
- ✅ Conventions de nommage respectées
- ✅ Code Python moderne
- ✅ Utilisation des nouveaux widgets

### Actions Requises (Septembre 2025)
1. Mettre à jour la version dans `__manifest__.py` : `19.0.1.0.0`
2. Tester la compatibilité avec les nouvelles fonctionnalités IA
3. Adapter aux nouveaux composants UI si nécessaire
4. Profiter des améliorations de performance

## 📚 Ressources

### Documentation Officielle
- [Odoo Developer Documentation](https://www.odoo.com/documentation/19.0/developer.html)
- [ORM Guidelines](https://www.odoo.com/documentation/19.0/developer/reference/backend/orm.html)
- [JavaScript Framework](https://www.odoo.com/documentation/19.0/developer/reference/frontend/javascript.html)

### Outils de Développement
- **VSCode Extensions** : Odoo Snippets, Python
- **Debug** : Mode développeur Odoo
- **Tests** : Framework de test intégré
- **Profiling** : Odoo profiler

### Communauté
- [Odoo Community Association (OCA)](https://github.com/OCA)
- [Forum Odoo](https://www.odoo.com/forum)
- [Discord Communauté](https://discord.gg/odoo)

## 🆘 Aide et Support

### Erreurs Courantes
| Erreur | Solution |
|--------|----------|
| Addon non détecté | Redémarrer le service web |
| Erreur d'import | Vérifier `__init__.py` |
| Droits d'accès | Mettre à jour `ir.model.access.csv` |
| Vue non trouvée | Vérifier le nom dans le XML |

### Debug
```python
# Dans le code Python d'un addon
import logging
_logger = logging.getLogger(__name__)

def ma_methode(self):
    _logger.info("Debug info: %s", self.name)
```

### Tests
```python
# tests/test_mon_addon.py
from odoo.tests.common import TransactionCase

class TestMonAddon(TransactionCase):
    def test_creation_record(self):
        record = self.env['mon_addon.model'].create({
            'name': 'Test'
        })
        self.assertEqual(record.name, 'Test')
```

---

**🎯 Objectif : Créer des addons robustes et maintenables pour Odoo 19**

*Happy coding! 🚀*