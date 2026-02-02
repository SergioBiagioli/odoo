FROM python:3.11-slim-bookworm

# Argumentos de build
ARG ODOO_VERSION=18.0

# Variables de entorno
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Dependencias de build
    build-essential \
    gcc \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libpq-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    libjpeg-dev \
    zlib1g-dev \
    # Dependencias de runtime
    postgresql-client \
    wkhtmltopdf \
    xfonts-75dpi \
    xfonts-base \
    fontconfig \
    # Utilidades
    curl \
    git \
    node-less \
    npm \
    # Limpieza
    && rm -rf /var/lib/apt/lists/*

# Instalar rtlcss para soporte RTL
RUN npm install -g rtlcss

# Crear usuario odoo
RUN useradd -m -d /opt/odoo -s /bin/bash odoo

# Directorio de trabajo
WORKDIR /opt/odoo

# Copiar requirements primero (para cache de Docker)
COPY requirements.txt /opt/odoo/
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de Odoo
COPY . /opt/odoo/odoo

# Instalar Odoo
WORKDIR /opt/odoo/odoo
RUN pip install --no-cache-dir -e .

# Crear directorios necesarios
RUN mkdir -p /var/lib/odoo /etc/odoo /mnt/extra-addons \
    && chown -R odoo:odoo /var/lib/odoo /etc/odoo /mnt/extra-addons /opt/odoo

# Copiar configuración
COPY ./docker/odoo.conf /etc/odoo/odoo.conf
COPY ./docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Cambiar a usuario odoo
USER odoo

# Puerto de Odoo (Cloud Run usa 8080)
EXPOSE 8080

# Volumen para filestore
VOLUME ["/var/lib/odoo"]

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
