FROM odoo:19
LABEL MAINTAINER="support@esacode.org"
LABEL VERSION="19.0-optimized"
LABEL DESCRIPTION="Odoo 19 optimized Docker image with AI features and performance enhancements"

USER root

# Mise à jour du système et installation des dépendances
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        build-essential \
        sox \
        python3 \
        python3-dev \
        python3-pip \
        git \
        curl \
        wget \
        nano \
        htop \
        postgresql-client \
        wkhtmltopdf \
        fonts-liberation \
        fonts-dejavu-core \
        fontconfig \
        libxrender1 \
        libfontconfig1 \
        libx11-6 \
        libjpeg-turbo8-dev \
        libxtst6 \
        xfonts-75dpi \
        xfonts-base && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Installation des dépendances Python pour Odoo 19 (IA, performance)
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt

# Dépendances spécifiques pour Odoo 19 IA (optionnelles, à installer selon les besoins)
# RUN pip3 install --no-cache-dir --break-system-packages \
#     openai \
#     anthropic \
#     langchain \
#     transformers \
#     torch \
#     scikit-learn

# Création des répertoires nécessaires
RUN mkdir -p /mnt/extra-addons \
             /var/lib/odoo/filestore \
             /var/lib/odoo/sessions \
             /etc/odoo/scripts

# Configuration des permissions
RUN chown -R odoo:odoo /mnt/extra-addons \
                       /var/lib/odoo \
                       /etc/odoo

# Script de healthcheck
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Script d'initialisation
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER odoo

# Healthcheck pour Docker
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["odoo"]