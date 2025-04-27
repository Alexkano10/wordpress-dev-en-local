#!/usr/bin/env bash
set -e

# 1. Asegurarnos de que ejecutamos desde la raíz del proyecto
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "✅ Creando carpetas 'wordpress/' y 'database/' si no existen..."
mkdir -p wordpress database

# 2. Arrancar los contenedores en segundo plano
echo "🚀 Levantando servicios con Docker Compose..."
docker compose up -d

# 3. Esperar a que MySQL acepte conexiones
echo -n "⏳ Esperando a que MySQL esté listo"
until docker exec wp_db mysqladmin ping -h "127.0.0.1" --silent &> /dev/null; do
  printf "."
  sleep 2
done
echo " OK"

# 4. Mostrar URL de acceso
echo "🎉 ¡Entorno listo! Accede a WordPress en http://localhost:8000"
