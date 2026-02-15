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

# === TEMP: fetch Updraft backup set (multiple files) into wp-content/updraft ===
UPDRAFT_DIR="/var/www/html/wp-content/updraft"

# 1) Déclare ici tes fichiers + URLs (1 ligne = 1 fichier)
#    IMPORTANT : garde exactement les noms de fichiers Updraft
FILES=(
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-db.gz|https://drive.google.com/file/d/1Rxx2J6CMAGdPjy6wvtdV2aOvXDRHH1Ia/view?usp=sharing"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-plugins.zip|https://drive.google.com/file/d/1L98nlGp6i6PKvAATCfBNAHTxth3c0lzQ/view?usp=sharing"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-themes.zip|https://drive.google.com/file/d/1FApjpmx0AezeuGhelXm5BJwQew57pbHN/view?usp=sharing"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-uploads.zip|https://drive.google.com/file/d/1yvbjoBXtvU5Y-vmvM6stCY1bci6ra6uV/view?usp=sharing"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-others.zip|https://drive.google.com/file/d/1kBIqppyyzGIayvGehrME95z60B7Jo-4t/view?usp=sharing"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-mu-plugins.zip|https://drive.google.com/file/d/12UJ1sj85rGVWmUJ9IiN-MSlcr-K0_Q1R/view?usp=sharing"
)

mkdir -p "$UPDRAFT_DIR"

echo "== Ensuring curl is installed =="
apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*

echo "== Downloading Updraft backup files (if missing) =="
for entry in "${FILES[@]}"; do
  IFS="|" read -r filename url <<< "$entry"

  if [ -z "$filename" ] || [ -z "$url" ]; then
    echo "ERROR: Missing filename or url in FILES entry: $entry"
    exit 1
  fi

  target="${UPDRAFT_DIR}/${filename}"

  if [ -f "$target" ]; then
    echo "OK (exists) - $filename"
    ls -lh "$target" || true
    continue
  fi

  echo "Downloading - $filename"
  echo "URL=$url"

  # Téléchargement robuste
  curl -L --fail --retry 5 --retry-delay 3 -o "$target" "$url"

  # Sanity check (fichier non vide)
  if [ ! -s "$target" ]; then
    echo "ERROR: Downloaded file is empty: $filename"
    rm -f "$target"
    exit 1
  fi

  ls -lh "$target" || true
done

echo "== Updraft files present in ${UPDRAFT_DIR} =="
ls -lh "$UPDRAFT_DIR" || true
# === /TEMP ===


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
