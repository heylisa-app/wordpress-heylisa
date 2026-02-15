FROM wordpress:php8.2-fpm

# Install nginx + netcat
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    netcat-openbsd \
  && rm -rf /var/lib/apt/lists/*

# PHP limits + display errors
RUN { \
    echo "upload_max_filesize=1024M"; \
    echo "post_max_size=1024M"; \
    echo "memory_limit=512M"; \
    echo "max_execution_time=300"; \
    echo "display_errors=On"; \
    echo "error_reporting=E_ALL"; \
  } > /usr/local/etc/php/conf.d/zzz-custom.ini

# Nginx config
RUN rm -f /etc/nginx/sites-enabled/default
RUN cat > /etc/nginx/sites-available/wordpress <<'EOF'
server {
  listen 8080;
  server_name _;
  root /var/www/html;
  index index.php index.html;
  client_max_body_size 1024M;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_param PHP_VALUE "display_errors=On";
    fastcgi_param PHP_VALUE "error_reporting=E_ALL";
  }
}
EOF

RUN ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress

# Copier notre wp-config.php custom
COPY wp-config.php /wp-config-custom.php

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
