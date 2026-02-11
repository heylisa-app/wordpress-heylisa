#!/usr/bin/env bash
set -e

echo "== Boot =="
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

# Config extra avec debug
export WORDPRESS_CONFIG_EXTRA=$'define("WP_DEBUG", true);\n'\
$'define("WP_DEBUG_LOG", true);\n'\
$'define("WP_DEBUG_DISPLAY", true);\n'\
$'@ini_set("mysqli.default_socket","");\n'\
$'@ini_set("pdo_mysql.default_socket","");\n'

echo "== Starting php-fpm =="
docker-entrypoint.sh php-fpm -D

echo "== Starting nginx =="
exec nginx -g "daemon off;"
