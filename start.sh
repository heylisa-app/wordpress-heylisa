#!/usr/bin/env bash
set -e

echo "== Boot =="

# Supprimer le fichier maintenance s'il existe
rm -f /var/www/html/.maintenance

echo "MYSQLHOST=${MYSQLHOST}"
echo "MYSQLPORT=${MYSQLPORT}"
echo "MYSQLDATABASE=${MYSQLDATABASE}"
echo "MYSQLUSER=${MYSQLUSER}"

# Attendre que MySQL soit accessible
echo "== Waiting for MySQL to be ready =="
until nc -z -v -w30 "${MYSQLHOST}" "${MYSQLPORT}"; do
  echo "Waiting for database connection..."
  sleep 2
done
echo "MySQL is up!"

# Variables WordPress (pour le wp-config.php)
export WORDPRESS_DB_HOST="${MYSQLHOST}:${MYSQLPORT}"
export WORDPRESS_DB_NAME="${MYSQLDATABASE}"
export WORDPRESS_DB_USER="${MYSQLUSER}"
export WORDPRESS_DB_PASSWORD="${MYSQLPASSWORD}"

# ⭐ Copier AVANT de démarrer PHP pour éviter un boot WP avec un mauvais config
echo "== Copying custom wp-config.php =="
cp /wp-config-custom.php /var/www/html/wp-config.php
chmod 644 /var/www/html/wp-config.php

echo "== Starting php-fpm =="
docker-entrypoint.sh php-fpm -D

echo "== Configuring nginx upload limits =="
cat > /etc/nginx/conf.d/uploads.conf <<'EOF'
client_max_body_size 256m;
client_body_timeout 300s;
client_header_timeout 300s;
send_timeout 300s;
EOF

echo "== Nginx conf written: =="
ls -l /etc/nginx/conf.d/uploads.conf || true

echo "== Starting nginx =="
exec nginx -g "daemon off;"
