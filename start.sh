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

# Variables WordPress (pour le wp-config.php)
export WORDPRESS_DB_HOST="${MYSQLHOST}:${MYSQLPORT}"
export WORDPRESS_DB_NAME="${MYSQLDATABASE}"
export WORDPRESS_DB_USER="${MYSQLUSER}"
export WORDPRESS_DB_PASSWORD="${MYSQLPASSWORD}"

echo "== Starting php-fpm =="
docker-entrypoint.sh php-fpm -D

# ⭐ IMPORTANT : Copier APRÈS que WordPress ait initialisé /var/www/html
echo "== Waiting for WordPress files to be ready =="
sleep 3

echo "== Copying custom wp-config.php =="
cp /wp-config-custom.php /var/www/html/wp-config.php
chmod 644 /var/www/html/wp-config.php

echo "== Starting nginx =="
exec nginx -g "daemon off;"
