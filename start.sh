#!/usr/bin/env bash
set -e

echo "== Boot =="
echo "MYSQLHOST=${MYSQLHOST}"
echo "MYSQLPORT=${MYSQLPORT}"
echo "MYSQLDATABASE=${MYSQLDATABASE}"
echo "MYSQLUSER=${MYSQLUSER}"
echo "PORT=${PORT}"

# Re-génère wp-config à chaque boot (pour éviter les états foireux)
rm -f /var/www/html/wp-config.php

# Variables WordPress standard attendues par l'image officielle
export WORDPRESS_DB_HOST="${MYSQLHOST}:${MYSQLPORT}"
export WORDPRESS_DB_NAME="${MYSQLDATABASE}"
export WORDPRESS_DB_USER="${MYSQLUSER}"
export WORDPRESS_DB_PASSWORD="${MYSQLPASSWORD}"

# Force: pas de socket implicite (évite HY000/2002 "No such file or directory")
export WORDPRESS_CONFIG_EXTRA=$'define("WP_DEBUG", true);\n'\
$'define("WP_DEBUG_LOG", true);\n'\
$'define("WP_DEBUG_DISPLAY", true);\n'\
$'@ini_set("mysqli.default_socket","");\n'\
$'@ini_set("pdo_mysql.default_socket","");\n'

echo "== Starting php-fpm (via official entrypoint) =="
docker-entrypoint.sh php-fpm -D

echo "== Starting nginx =="
exec nginx -g "daemon off;"
