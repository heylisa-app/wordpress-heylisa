FROM wordpress:php8.2-apache

# HARD FIX: ensure Apache loads only ONE MPM module (prefork)
RUN set -eux; \
  # remove any enabled MPM modules (symlinks) if present
  rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf || true; \
  rm -f /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf || true; \
  rm -f /etc/apache2/mods-enabled/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.conf || true; \
  \
  # enable prefork (create symlinks)
  a2enmod mpm_prefork; \
  \
  # sanity: disable others (even if not enabled)
  a2dismod mpm_event mpm_worker || true

# Increase limits for backups & restore (UpdraftPlus)
RUN { \
    echo "upload_max_filesize=256M"; \
    echo "post_max_size=256M"; \
    echo "memory_limit=512M"; \
    echo "max_execution_time=300"; \
  } > /usr/local/etc/php/conf.d/zzz-custom.ini
