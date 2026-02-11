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
until nc -z -v -w30 ${MYSQLHOST} ${MYSQLPORT}; do
  echo "Waiting for database connection..."
  sleep 2
done
echo "MySQL is up!"

# Re-génère wp-config à chaque boot
rm -f /var/www/html/wp-config.php

# Variables WordPress standard
export WORDPRESS_DB_HOST="${MYSQLHOST}:${MYSQLPORT}"
export WORDPRESS_DB_NAME="${MYSQLDATABASE}"
export WORDPRESS_DB_USER="${MYSQLUSER}"
export WORDPRESS_DB_PASSWORD="${MYSQLPASSWORD}"

# ⭐ IMPORTANT : définir AVANT php-fpm
export WORDPRESS_CONFIG_EXTRA="define('WP_HOME', 'https://wordpress-production-2b8e.up.railway.app');\ndefine('WP_SITEURL', 'https://wordpress-production-2b8e.up.railway.app');\ndefine('WP_DEBUG', true);\ndefine('WP_DEBUG_DISPLAY', true);\ndefine('WP_DEBUG_LOG', true);"

echo "== Starting php-fpm =="
docker-entrypoint.sh php-fpm -D

echo "== Starting nginx =="
exec nginx -g "daemon off;"
