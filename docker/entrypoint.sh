#!/bin/bash
set -e

# Función para esperar a que PostgreSQL esté listo
wait_for_postgres() {
    echo "Esperando a que PostgreSQL esté disponible..."
    
    # Para Cloud SQL via Unix socket
    if [[ "$DB_HOST" == /cloudsql/* ]]; then
        # Cloud SQL usa socket, verificamos que el directorio exista
        SOCKET_DIR=$(dirname "$DB_HOST")
        while [ ! -S "${DB_HOST}/.s.PGSQL.5432" ] 2>/dev/null; do
            echo "Esperando socket de Cloud SQL..."
            sleep 2
        done
    else
        # Conexión TCP tradicional
        while ! pg_isready -h "$DB_HOST" -U "$DB_USER" -q; do
            sleep 2
        done
    fi
    
    echo "PostgreSQL está disponible!"
}

# Generar configuración desde variables de entorno
generate_config() {
    cat > /tmp/odoo.conf << EOF
[options]
; Configuración de base de datos
db_host = ${DB_HOST:-localhost}
db_port = ${DB_PORT:-5432}
db_user = ${DB_USER:-odoo}
db_password = ${DB_PASSWORD:-odoo}
db_name = ${DB_NAME:-False}
db_filter = ${DB_FILTER:-.*}

; Configuración de red
http_port = ${ODOO_HTTP_PORT:-8080}
proxy_mode = ${ODOO_PROXY_MODE:-True}
xmlrpc_interface = 0.0.0.0
netrpc_interface = 0.0.0.0

; Paths
data_dir = /var/lib/odoo
addons_path = /opt/odoo/odoo/addons,/mnt/extra-addons

; Workers (0 = threaded mode, mejor para Cloud Run)
workers = ${ODOO_WORKERS:-0}
max_cron_threads = ${ODOO_CRON_THREADS:-1}

; Límites
limit_memory_hard = ${ODOO_LIMIT_MEMORY_HARD:-2684354560}
limit_memory_soft = ${ODOO_LIMIT_MEMORY_SOFT:-2147483648}
limit_time_cpu = ${ODOO_LIMIT_TIME_CPU:-600}
limit_time_real = ${ODOO_LIMIT_TIME_REAL:-1200}

; Logging
log_level = ${ODOO_LOG_LEVEL:-info}
logfile = False

; Seguridad
list_db = ${ODOO_LIST_DB:-False}
admin_passwd = ${ODOO_ADMIN_PASSWD:-admin}

; Otros
without_demo = ${ODOO_WITHOUT_DEMO:-True}
EOF
}

# Main
case "$1" in
    odoo)
        generate_config
        # wait_for_postgres  # Descomentar si necesitás esperar
        shift
        exec /opt/odoo/odoo/odoo-bin -c /tmp/odoo.conf "$@"
        ;;
    shell)
        generate_config
        exec /opt/odoo/odoo/odoo-bin shell -c /tmp/odoo.conf
        ;;
    *)
        exec "$@"
        ;;
esac
