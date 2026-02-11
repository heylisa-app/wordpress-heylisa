#!/usr/bin/env bash
set -e

# Generate wp-config.php at runtime if missing
if [ ! -f /var/www/html/wp-config.php ]; then
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
fi

# Let the official entrypoint do its job (wp core copy, etc.)
docker-entrypoint.sh php-fpm -D

# Run nginx in foreground
exec nginx -g "daemon off;"
