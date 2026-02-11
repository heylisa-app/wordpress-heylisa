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

# Start php-fpm + nginx together
CMD ["bash", "-lc", "docker-entrypoint.sh php-fpm -D && nginx -g 'daemon off;'"]
