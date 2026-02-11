#!/usr/bin/env bash
set -e

echo "🧹 Removing any existing wp-config.php"
rm -f /var/www/html/wp-config.php

echo "📝 Generating fresh wp-config.php from Railway MySQL env vars"

cat > /var/www/html/wp-config.php <<'EOF'
<?php
define('DB_NAME', getenv('MYSQLDATABASE'));
define('DB_USER', getenv('MYSQLUSER'));
define('DB_PASSWORD', getenv('MYSQLPASSWORD'));
define('DB_HOST', getenv('MYSQLHOST') . ':' . getenv('MYSQLPORT'));

define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

$table_prefix = 'wp_';

define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', true);

if ( ! defined('ABSPATH') ) {
  define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
EOF

echo "🚀 Starting PHP-FPM via official WordPress entrypoint"
docker-entrypoint.sh php-fpm -D

echo "🌐 Starting Nginx"
exec nginx -g "daemon off;"
