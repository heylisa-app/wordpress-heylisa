FROM wordpress:php8.2-fpm

# Install nginx
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
  && rm -rf /var/lib/apt/lists/*

# PHP limits (useful for Updraft restore)
RUN { \
    echo "upload_max_filesize=256M"; \
    echo "post_max_size=256M"; \
    echo "memory_limit=512M"; \
    echo "max_execution_time=300"; \
  } > /usr/local/etc/php/conf.d/zzz-custom.ini

# Nginx config (Railway uses $PORT, default 8080)
RUN rm -f /etc/nginx/sites-enabled/default
RUN cat > /etc/nginx/sites-available/wordpress <<'EOF'
server {
  listen 8080;
  server_name _;
  root /var/www/html;

  index index.php index.html;

  client_max_body_size 256M;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass 127.0.0.1:9000;
  }
}
EOF
RUN ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress

# Start php-fpm + nginx together (and generate wp-config.php at runtime)
CMD bash -lc '
if [ ! -f /var/www/html/wp-config.php ]; then
cat > /var/www/html/wp-config.php <<'"'"'EOF'"'"'
<?php
define('"'"'DB_NAME'"'"', getenv('"'"'MYSQLDATABASE'"'"'));
define('"'"'DB_USER'"'"', getenv('"'"'MYSQLUSER'"'"'));
define('"'"'DB_PASSWORD'"'"', getenv('"'"'MYSQLPASSWORD'"'"'));
define('"'"'DB_HOST'"'"', getenv('"'"'MYSQLHOST'"'"') . '"'"':'"'"' . getenv('"'"'MYSQLPORT'"'"'));

define('"'"'DB_CHARSET'"'"', '"'"'utf8mb4'"'"');
define('"'"'DB_COLLATE'"'"', '"'"''"'"');

$table_prefix = '"'"'wp_'"'"';

define('"'"'WP_DEBUG'"'"', true);
define('"'"'WP_DEBUG_LOG'"'"', true);
define('"'"'WP_DEBUG_DISPLAY'"'"', true);

if ( ! defined('"'"'ABSPATH'"'"') ) {
  define('"'"'ABSPATH'"'"', __DIR__ . '"'"'/'"'"');
}
require_once ABSPATH . '"'"'wp-settings.php'"'"';
EOF
fi

docker-entrypoint.sh php-fpm -D
exec nginx -g "daemon off;"
'
