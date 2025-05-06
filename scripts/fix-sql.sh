#!/usr/bin/env bash
set -e

# Siempre desde la raíz del proyecto
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

ENV_DB=$(grep MYSQL_DATABASE .env | cut -d "=" -f2)
SQL_FILE="database/initdb/init.sql"

if [ ! -f "$SQL_FILE" ]; then
  echo "❌ Archivo SQL no encontrado: $SQL_FILE"
  exit 1
fi

if ! grep -qi "use $ENV_DB" "$SQL_FILE"; then
  echo "⚠️  No se encontró 'USE $ENV_DB' en $SQL_FILE. Añadiendo al inicio..."
  sed -i "1i USE ${ENV_DB};\n" "$SQL_FILE"
else
  echo "✅ El archivo SQL ya contiene 'USE $ENV_DB'"
fi

