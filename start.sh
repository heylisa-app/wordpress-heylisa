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
until nc -z -v -w30 "${MYSQLHOST}" "${MYSQLPORT}"; do
  echo "Waiting for database connection..."
  sleep 2
done
echo "MySQL is up!"

# Variables WordPress (pour le wp-config.php)
export WORDPRESS_DB_HOST="${MYSQLHOST}:${MYSQLPORT}"
export WORDPRESS_DB_NAME="${MYSQLDATABASE}"
export WORDPRESS_DB_USER="${MYSQLUSER}"
export WORDPRESS_DB_PASSWORD="${MYSQLPASSWORD}"

# === TEMP: fetch Updraft backup set (Google Drive) into wp-content/updraft ===
UPDRAFT_DIR="/var/www/html/wp-content/updraft"

# Format: "filename|FILE_ID"
FILES=(
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-db.gz|1Rxx2J6CMAGdPjy6wvtdV2aOvXDRHH1Ia"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-plugins.zip|1L98nlGp6i6PKvAATCfBNAHTxth3c0lzQ"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-themes.zip|1FApjpmx0AezeuGhelXm5BJwQew57pbHN"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-uploads.zip|1yvbjoBXtvU5Y-vmvM6stCY1bci6ra6uV"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-others.zip|1kBIqppyyzGIayvGehrME95z60B7Jo-4t"
  "backup_2026-02-15-1738_HeyLisa_e6bc89837805-mu-plugins.zip|12UJ1sj85rGVWmUJ9IiN-MSlcr-K0_Q1R"
)

mkdir -p "$UPDRAFT_DIR"

echo "== Ensuring curl is installed =="
apt-get update && apt-get install -y --no-install-recommends curl ca-certificates unzip gzip file && rm -rf /var/lib/apt/lists/*

download_gdrive () {
  local file_id="$1"
  local out="$2"
  local cookie="/tmp/gcookie.txt"

  rm -f "$cookie"

  # 1) hit Drive once to get confirm token (if any) + cookies
  local confirm
  confirm=$(curl -s -c "$cookie" "https://drive.google.com/uc?export=download&id=${file_id}" \
    | sed -n 's/.*confirm=\([0-9A-Za-z_]\+\).*/\1/p' | head -n 1)

  # 2) download with confirm token if present
  if [ -n "$confirm" ]; then
    curl -L -b "$cookie" --fail --retry 5 --retry-delay 3 \
      -o "$out" "https://drive.google.com/uc?export=download&confirm=${confirm}&id=${file_id}"
  else
    curl -L -b "$cookie" --fail --retry 5 --retry-delay 3 \
      -o "$out" "https://drive.google.com/uc?export=download&id=${file_id}"
  fi
}

echo "== Downloading Updraft backup files (if missing) =="
for entry in "${FILES[@]}"; do
  IFS="|" read -r filename file_id <<< "$entry"
  target="${UPDRAFT_DIR}/${filename}"

  if [ -f "$target" ] && [ -s "$target" ]; then
    echo "OK (exists) - $filename"
    ls -lh "$target" || true
    continue
  fi

  echo "Downloading - $filename (id=$file_id)"
  rm -f "$target"

  download_gdrive "$file_id" "$target"

  # Sanity: non-empty
  if [ ! -s "$target" ]; then
    echo "ERROR: Downloaded file is empty: $filename"
    exit 1
  fi

  # Sanity: refuse HTML (Drive interstitial)
  if head -c 200 "$target" | grep -qiE '<!doctype html|<html'; then
    echo "ERROR: Downloaded HTML instead of binary for $filename (Drive interstitial)."
    echo "First bytes:"
    head -c 200 "$target" || true
    exit 1
  fi

  # Validate archive quickly
  if echo "$filename" | grep -q '\.zip$'; then
    unzip -t "$target" >/dev/null || { echo "ERROR: ZIP test failed for $filename"; exit 1; }
  fi
  if echo "$filename" | grep -q '\-db\.gz$'; then
    gzip -t "$target" || { echo "ERROR: GZ test failed for $filename"; exit 1; }
  fi

  echo "OK - $filename"
  ls -lh "$target" || true
done

echo "== Updraft files present in ${UPDRAFT_DIR} =="
ls -lh "$UPDRAFT_DIR" || true
# === /TEMP ===

# ⭐ Copier AVANT de démarrer PHP pour éviter un boot WP avec un mauvais config
echo "== Copying custom wp-config.php =="
cp /wp-config-custom.php /var/www/html/wp-config.php
chmod 644 /var/www/html/wp-config.php

echo "== Starting php-fpm =="
docker-entrypoint.sh php-fpm -D

echo "== Starting nginx =="
exec nginx -g "daemon off;"
