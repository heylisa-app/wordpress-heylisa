FROM wordpress:php8.2-apache

# Fix Apache MPM conflict on Railway
RUN a2dismod mpm_event mpm_worker 2>/dev/null || true \
 && a2enmod mpm_prefork

# Increase limits for backups & restore
RUN { \
    echo "upload_max_filesize=256M"; \
    echo "post_max_size=256M"; \
    echo "memory_limit=512M"; \
    echo "max_execution_time=300"; \
  } > /usr/local/etc/php/conf.d/zzz-custom.ini
