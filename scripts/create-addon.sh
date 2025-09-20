#!/bin/bash
# Script de création d'addon pour Odoo 19
# Usage: ./create-addon.sh nom_de_l_addon [description]

set -e

ADDON_NAME="$1"
ADDON_DESCRIPTION="${2:-Mon nouvel addon Odoo}"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -z "$ADDON_NAME" ]; then
    echo -e "${RED}❌ Usage: ./create-addon.sh nom_de_l_addon [description]${NC}"
    echo -e "${BLUE}💡 Exemple: ./create-addon.sh mon_module 'Gestion de mes données'${NC}"
    exit 1
fi

# Validation du nom de l'addon
if [[ ! "$ADDON_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo -e "${RED}❌ Le nom de l'addon doit commencer par une lettre minuscule et ne contenir que des lettres, chiffres et underscores${NC}"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADDON_DIR="$PROJECT_DIR/odoo/addons/$ADDON_NAME"

echo -e "${BLUE}🚀 Création de l'addon '$ADDON_NAME'${NC}"
echo -e "${YELLOW}📁 Répertoire: $ADDON_DIR${NC}"
echo -e "${YELLOW}📝 Description: $ADDON_DESCRIPTION${NC}"

# Vérifier si l'addon existe déjà
if [ -d "$ADDON_DIR" ]; then
    echo -e "${RED}❌ L'addon '$ADDON_NAME' existe déjà${NC}"
    exit 1
fi

# Créer la structure de l'addon
echo -e "${BLUE}📁 Création de la structure...${NC}"
mkdir -p "$ADDON_DIR"/{models,views,static/{description,src/{css,js,xml}},security,data,demo,wizard,report,controllers}

# Créer le fichier __init__.py principal
cat > "$ADDON_DIR/__init__.py" << 'EOF'
# -*- coding: utf-8 -*-
from . import models
from . import controllers
EOF

# Créer le fichier __manifest__.py
cat > "$ADDON_DIR/__manifest__.py" << EOF
# -*- coding: utf-8 -*-
{
    'name': '$ADDON_DESCRIPTION',
    'version': '19.0.1.0.0',
    'depends': ['base'],
    'author': 'Votre Nom',
    'category': 'Custom',
    'description': """
$ADDON_DESCRIPTION
==================

Description détaillée de votre addon.

Fonctionnalités:
    * Fonctionnalité 1
    * Fonctionnalité 2
    * Fonctionnalité 3
    """,
    'data': [
        'security/ir.model.access.csv',
        'views/${ADDON_NAME}_views.xml',
        'data/${ADDON_NAME}_data.xml',
    ],
    'demo': [
        'demo/${ADDON_NAME}_demo.xml',
    ],
    'qweb': [
        'static/src/xml/${ADDON_NAME}_templates.xml',
    ],
    'installable': True,
    'auto_install': False,
    'application': False,
    'license': 'LGPL-3',
}
EOF

# Créer models/__init__.py
cat > "$ADDON_DIR/models/__init__.py" << EOF
# -*- coding: utf-8 -*-
from . import ${ADDON_NAME}_model
EOF

# Créer un modèle exemple
MODEL_CLASS=$(echo "$ADDON_NAME" | sed 's/_/ /g' | sed 's/\b\w/\U&/g' | sed 's/ //g')
cat > "$ADDON_DIR/models/${ADDON_NAME}_model.py" << EOF
# -*- coding: utf-8 -*-

from odoo import models, fields, api
from odoo.exceptions import ValidationError


class $MODEL_CLASS(models.Model):
    _name = '${ADDON_NAME}.${ADDON_NAME}'
    _description = '$ADDON_DESCRIPTION'
    _order = 'name'

    name = fields.Char(
        string='Nom',
        required=True,
        help='Nom de l\'enregistrement'
    )

    description = fields.Text(
        string='Description',
        help='Description détaillée'
    )

    active = fields.Boolean(
        string='Actif',
        default=True,
        help='Décochez pour archiver l\'enregistrement'
    )

    state = fields.Selection([
        ('draft', 'Brouillon'),
        ('confirmed', 'Confirmé'),
        ('done', 'Terminé'),
        ('cancelled', 'Annulé'),
    ], string='État', default='draft', required=True)

    date_created = fields.Datetime(
        string='Date de création',
        default=fields.Datetime.now,
        readonly=True
    )

    user_id = fields.Many2one(
        'res.users',
        string='Utilisateur responsable',
        default=lambda self: self.env.user
    )

    @api.constrains('name')
    def _check_name(self):
        for record in self:
            if not record.name or len(record.name.strip()) < 3:
                raise ValidationError("Le nom doit contenir au moins 3 caractères.")

    def action_confirm(self):
        """Confirmer l'enregistrement"""
        self.write({'state': 'confirmed'})
        return True

    def action_done(self):
        """Marquer comme terminé"""
        self.write({'state': 'done'})
        return True

    def action_cancel(self):
        """Annuler l'enregistrement"""
        self.write({'state': 'cancelled'})
        return True

    def action_reset_to_draft(self):
        """Remettre en brouillon"""
        self.write({'state': 'draft'})
        return True
EOF

# Créer controllers/__init__.py
cat > "$ADDON_DIR/controllers/__init__.py" << EOF
# -*- coding: utf-8 -*-
from . import ${ADDON_NAME}_controller
EOF

# Créer un contrôleur exemple
cat > "$ADDON_DIR/controllers/${ADDON_NAME}_controller.py" << EOF
# -*- coding: utf-8 -*-

from odoo import http
from odoo.http import request


class ${MODEL_CLASS}Controller(http.Controller):

    @http.route('/${ADDON_NAME}', auth='public', website=True)
    def ${ADDON_NAME}_page(self, **kwargs):
        """Page publique pour $ADDON_NAME"""
        records = request.env['${ADDON_NAME}.${ADDON_NAME}'].sudo().search([])
        return request.render('${ADDON_NAME}.${ADDON_NAME}_page_template', {
            'records': records,
        })

    @http.route('/${ADDON_NAME}/api/records', auth='user', methods=['GET'], type='json')
    def get_records_api(self, **kwargs):
        """API pour récupérer les enregistrements"""
        records = request.env['${ADDON_NAME}.${ADDON_NAME}'].search([])
        return [{
            'id': record.id,
            'name': record.name,
            'description': record.description,
            'state': record.state,
        } for record in records]
EOF

# Créer les vues XML
cat > "$ADDON_DIR/views/${ADDON_NAME}_views.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <!-- Vue liste -->
    <record id="${ADDON_NAME}_tree_view" model="ir.ui.view">
        <field name="name">${ADDON_NAME}.tree</field>
        <field name="model">${ADDON_NAME}.${ADDON_NAME}</field>
        <field name="arch" type="xml">
            <tree>
                <field name="name"/>
                <field name="state"/>
                <field name="user_id"/>
                <field name="date_created"/>
            </tree>
        </field>
    </record>

    <!-- Vue formulaire -->
    <record id="${ADDON_NAME}_form_view" model="ir.ui.view">
        <field name="name">${ADDON_NAME}.form</field>
        <field name="model">${ADDON_NAME}.${ADDON_NAME}</field>
        <field name="arch" type="xml">
            <form>
                <header>
                    <button name="action_confirm" string="Confirmer"
                            type="object" class="oe_highlight"
                            states="draft"/>
                    <button name="action_done" string="Terminer"
                            type="object" class="oe_highlight"
                            states="confirmed"/>
                    <button name="action_cancel" string="Annuler"
                            type="object" states="draft,confirmed"/>
                    <button name="action_reset_to_draft" string="Remettre en brouillon"
                            type="object" states="cancelled"/>
                    <field name="state" widget="statusbar"
                           statusbar_visible="draft,confirmed,done"/>
                </header>
                <sheet>
                    <group>
                        <group>
                            <field name="name"/>
                            <field name="user_id"/>
                        </group>
                        <group>
                            <field name="active"/>
                            <field name="date_created"/>
                        </group>
                    </group>
                    <notebook>
                        <page string="Description">
                            <field name="description"/>
                        </page>
                    </notebook>
                </sheet>
            </form>
        </field>
    </record>

    <!-- Vue recherche -->
    <record id="${ADDON_NAME}_search_view" model="ir.ui.view">
        <field name="name">${ADDON_NAME}.search</field>
        <field name="model">${ADDON_NAME}.${ADDON_NAME}</field>
        <field name="arch" type="xml">
            <search>
                <field name="name"/>
                <field name="description"/>
                <field name="user_id"/>
                <filter string="Mes enregistrements" name="my_records"
                        domain="[('user_id', '=', uid)]"/>
                <filter string="Brouillons" name="draft"
                        domain="[('state', '=', 'draft')]"/>
                <filter string="Confirmés" name="confirmed"
                        domain="[('state', '=', 'confirmed')]"/>
                <separator/>
                <filter string="Archivés" name="inactive"
                        domain="[('active', '=', False)]"/>
                <group expand="0" string="Grouper par">
                    <filter string="État" name="group_state"
                            context="{'group_by': 'state'}"/>
                    <filter string="Utilisateur" name="group_user"
                            context="{'group_by': 'user_id'}"/>
                </group>
            </search>
        </field>
    </record>

    <!-- Actions -->
    <record id="${ADDON_NAME}_action" model="ir.actions.act_window">
        <field name="name">$ADDON_DESCRIPTION</field>
        <field name="res_model">${ADDON_NAME}.${ADDON_NAME}</field>
        <field name="view_mode">tree,form</field>
        <field name="context">{'search_default_my_records': 1}</field>
        <field name="help" type="html">
            <p class="o_view_nocontent_smiling_face">
                Créer votre premier enregistrement $ADDON_NAME
            </p>
            <p>
                Cliquez sur "Créer" pour commencer.
            </p>
        </field>
    </record>

    <!-- Menu -->
    <menuitem id="${ADDON_NAME}_menu_root" name="$ADDON_DESCRIPTION" sequence="10"/>
    <menuitem id="${ADDON_NAME}_menu" name="$ADDON_DESCRIPTION"
              parent="${ADDON_NAME}_menu_root"
              action="${ADDON_NAME}_action" sequence="1"/>

</odoo>
EOF

# Créer le fichier de sécurité
cat > "$ADDON_DIR/security/ir.model.access.csv" << EOF
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_${ADDON_NAME}_user,${ADDON_NAME}.${ADDON_NAME}.user,model_${ADDON_NAME}_${ADDON_NAME},base.group_user,1,1,1,1
access_${ADDON_NAME}_manager,${ADDON_NAME}.${ADDON_NAME}.manager,model_${ADDON_NAME}_${ADDON_NAME},base.group_system,1,1,1,1
EOF

# Créer les données de base
cat > "$ADDON_DIR/data/${ADDON_NAME}_data.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data noupdate="1">

        <!-- Données de configuration -->

    </data>
</odoo>
EOF

# Créer les données de démonstration
cat > "$ADDON_DIR/demo/${ADDON_NAME}_demo.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data noupdate="1">

        <!-- Enregistrement de démonstration 1 -->
        <record id="${ADDON_NAME}_demo_1" model="${ADDON_NAME}.${ADDON_NAME}">
            <field name="name">Exemple 1</field>
            <field name="description">Ceci est un exemple d'enregistrement pour la démonstration.</field>
            <field name="state">draft</field>
        </record>

        <!-- Enregistrement de démonstration 2 -->
        <record id="${ADDON_NAME}_demo_2" model="${ADDON_NAME}.${ADDON_NAME}">
            <field name="name">Exemple 2</field>
            <field name="description">Un autre exemple d'enregistrement de démonstration.</field>
            <field name="state">confirmed</field>
        </record>

    </data>
</odoo>
EOF

# Créer l'icône de l'addon
mkdir -p "$ADDON_DIR/static/description"
cat > "$ADDON_DIR/static/description/icon.png.info" << EOF
# Icône de l'addon
# Placez votre icône PNG (128x128px) ici et nommez-la 'icon.png'
# Ou utilisez le générateur d'icône en ligne sur apps.odoo.com
EOF

# Créer un template JS basique
cat > "$ADDON_DIR/static/src/js/${ADDON_NAME}.js" << EOF
odoo.define('${ADDON_NAME}.${ADDON_NAME}', function (require) {
"use strict";

var core = require('web.core');
var Widget = require('web.Widget');

var _t = core._t;

var ${MODEL_CLASS}Widget = Widget.extend({
    template: '${ADDON_NAME}.${ADDON_NAME}Template',

    init: function(parent, options) {
        this._super.apply(this, arguments);
        this.options = options || {};
    },

    start: function() {
        var self = this;
        return this._super().then(function() {
            self.\$el.on('click', '.${ADDON_NAME}-button', self._onButtonClick.bind(self));
        });
    },

    _onButtonClick: function(event) {
        event.preventDefault();
        console.log('${ADDON_NAME} button clicked');
    },
});

return ${MODEL_CLASS}Widget;

});
EOF

# Créer un template XML pour JS
cat > "$ADDON_DIR/static/src/xml/${ADDON_NAME}_templates.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<templates>

    <t t-name="${ADDON_NAME}.${ADDON_NAME}Template">
        <div class="${ADDON_NAME}-widget">
            <h3>$ADDON_DESCRIPTION</h3>
            <button class="btn btn-primary ${ADDON_NAME}-button">
                Cliquez-moi
            </button>
        </div>
    </t>

</templates>
EOF

# Créer un fichier CSS basique
cat > "$ADDON_DIR/static/src/css/${ADDON_NAME}.css" << EOF
/* Styles pour $ADDON_NAME */

.${ADDON_NAME}-widget {
    padding: 20px;
    border: 1px solid #ddd;
    border-radius: 5px;
    margin: 10px 0;
}

.${ADDON_NAME}-widget h3 {
    color: #875A7B;
    margin-bottom: 15px;
}

.${ADDON_NAME}-button {
    background-color: #875A7B;
    border-color: #875A7B;
}

.${ADDON_NAME}-button:hover {
    background-color: #7C4876;
    border-color: #7C4876;
}
EOF

# Créer un README pour l'addon
cat > "$ADDON_DIR/README.md" << EOF
# $ADDON_DESCRIPTION

## Description

$ADDON_DESCRIPTION est un addon Odoo 19 qui fournit...

## Fonctionnalités

- ✅ Gestion des enregistrements $ADDON_NAME
- ✅ Interface utilisateur intuitive
- ✅ API REST pour l'intégration
- ✅ Workflow avec états (brouillon, confirmé, terminé, annulé)
- ✅ Sécurité et droits d'accès
- ✅ Données de démonstration

## Installation

1. Copiez le dossier \`$ADDON_NAME\` dans \`/mnt/extra-addons\`
2. Redémarrez Odoo
3. Activez le mode développeur
4. Allez dans Apps → Mettre à jour la liste des apps
5. Recherchez "$ADDON_DESCRIPTION" et installez

## Configuration

Après installation, vous trouverez le menu "$ADDON_DESCRIPTION" dans l'interface Odoo.

## Utilisation

### Interface utilisateur

1. Accédez au menu "$ADDON_DESCRIPTION"
2. Créez de nouveaux enregistrements
3. Gérez les workflows avec les boutons d'état

### API

Endpoint disponible : \`/\${ADDON_NAME}/api/records\`

\`\`\`python
# Exemple d'utilisation Python
import requests

response = requests.get('http://votre-odoo.com/${ADDON_NAME}/api/records',
                       auth=('user', 'password'))
data = response.json()
\`\`\`

## Développement

### Structure des fichiers

\`\`\`
${ADDON_NAME}/
├── __init__.py
├── __manifest__.py
├── models/
├── views/
├── controllers/
├── static/
├── security/
├── data/
└── demo/
\`\`\`

### Tests

\`\`\`bash
# Exécuter les tests
docker-compose exec web odoo -d odoo_19_base --test-enable --stop-after-init -i $ADDON_NAME
\`\`\`

## Support

Pour toute question ou bug, créez une issue sur le dépôt GitHub.

## Licence

LGPL-3
EOF

echo -e "\n${GREEN}🎉 Addon '$ADDON_NAME' créé avec succès !${NC}"
echo -e "${BLUE}📁 Emplacement: $ADDON_DIR${NC}"
echo -e "\n${YELLOW}📋 Prochaines étapes:${NC}"
echo -e "${YELLOW}   1. Personnalisez le fichier __manifest__.py${NC}"
echo -e "${YELLOW}   2. Modifiez les modèles dans models/${ADDON_NAME}_model.py${NC}"
echo -e "${YELLOW}   3. Adaptez les vues dans views/${ADDON_NAME}_views.xml${NC}"
echo -e "${YELLOW}   4. Ajoutez une icône dans static/description/icon.png${NC}"
echo -e "${YELLOW}   5. Redémarrez Odoo: docker-compose restart web${NC}"
echo -e "${YELLOW}   6. Installez l'addon depuis l'interface Odoo${NC}"

echo -e "\n${BLUE}💡 Commandes utiles:${NC}"
echo -e "${BLUE}   - Installer: docker-compose exec web odoo -d odoo_19_base -i $ADDON_NAME --stop-after-init${NC}"
echo -e "${BLUE}   - Mettre à jour: docker-compose exec web odoo -d odoo_19_base -u $ADDON_NAME --stop-after-init${NC}"
echo -e "${BLUE}   - Tests: docker-compose exec web odoo -d odoo_19_base --test-enable -i $ADDON_NAME --stop-after-init${NC}"