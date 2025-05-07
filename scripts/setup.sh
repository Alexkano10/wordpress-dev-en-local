#!/bin/bash

# Script para configurar y ejecutar un entorno de WordPress con Docker
# Asegurarse de ejecutar este script desde la raíz del proyecto

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Obtener directorio raíz del proyecto
ROOT_DIR="$(pwd)"

# Función para mostrar el banner
show_banner() {
    clear
    echo -e "${BLUE}╔═════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                         ║${NC}"
    echo -e "${BLUE}║     ${GREEN}WordPress Docker Environment Setup Script${BLUE}            ║${NC}"
    echo -e "${BLUE}║                                                         ║${NC}"
    echo -e "${BLUE}╚═════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para crear directorios necesarios
create_directories() {
    echo -e "${YELLOW}Creando estructura de directorios...${NC}"
    
    # Crear directorios si no existen
    mkdir -p "$ROOT_DIR/wordpress"
    mkdir -p "$ROOT_DIR/database/initdb"

     # 🔐 Fijar permisos en init.sql
    INIT_SQL="$ROOT_DIR/database/initdb/init.sql"
    if [[ -f "$INIT_SQL" ]]; then
      chmod 644 "$INIT_SQL"
      chown $USER:$USER "$INIT_SQL"
      echo -e "${GREEN}✓ Permisos corregidos en database/initdb/init.sql${NC}"
    fi
    
    echo -e "${GREEN}✓ Estructura de directorios creada correctamente${NC}"
    echo ""
}

# Función para crear archivo .env
create_env_file() {
    show_banner
    echo -e "${BLUE}=== Configuración del archivo .env ===${NC}"
    echo -e "Por favor, introduce los valores para la configuración (o presiona Enter para usar los valores por defecto):"
    echo ""
    
    # Variables con valores por defecto
    DEFAULT_MYSQL_ROOT_PASSWORD="root123"
    DEFAULT_MYSQL_DATABASE="wordpress"
    DEFAULT_MYSQL_USER="alex"
    DEFAULT_MYSQL_PASSWORD="alex123"
    DEFAULT_WORDPRESS_TABLE_PREFIX="wp_"
    DEFAULT_MYSQL_VERSION="8.0"
    DEFAULT_WORDPRESS_VERSION="latest"
    
    # Solicitar valores al usuario
    read -p "Contraseña de root MySQL [$DEFAULT_MYSQL_ROOT_PASSWORD]: " MYSQL_ROOT_PASSWORD
    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$DEFAULT_MYSQL_ROOT_PASSWORD}
    
    read -p "Nombre de base de datos [$DEFAULT_MYSQL_DATABASE]: " MYSQL_DATABASE
    MYSQL_DATABASE=${MYSQL_DATABASE:-$DEFAULT_MYSQL_DATABASE}
    
    read -p "Usuario MySQL [$DEFAULT_MYSQL_USER]: " MYSQL_USER
    MYSQL_USER=${MYSQL_USER:-$DEFAULT_MYSQL_USER}
    
    read -p "Contraseña de usuario MySQL [$DEFAULT_MYSQL_PASSWORD]: " MYSQL_PASSWORD
    MYSQL_PASSWORD=${MYSQL_PASSWORD:-$DEFAULT_MYSQL_PASSWORD}
    
    read -p "Prefijo de tablas WordPress [$DEFAULT_WORDPRESS_TABLE_PREFIX]: " WORDPRESS_TABLE_PREFIX
    WORDPRESS_TABLE_PREFIX=${WORDPRESS_TABLE_PREFIX:-$DEFAULT_WORDPRESS_TABLE_PREFIX}
    
    read -p "Versión MySQL [$DEFAULT_MYSQL_VERSION]: " MYSQL_VERSION
    MYSQL_VERSION=${MYSQL_VERSION:-$DEFAULT_MYSQL_VERSION}
    
    read -p "Versión WordPress [$DEFAULT_WORDPRESS_VERSION]: " WORDPRESS_VERSION
    WORDPRESS_VERSION=${WORDPRESS_VERSION:-$DEFAULT_WORDPRESS_VERSION}
    
    # Mostrar resumen de configuración
    echo ""
    echo -e "${BLUE}=== Resumen de configuración ===${NC}"
    echo -e "MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD"
    echo -e "MYSQL_DATABASE: $MYSQL_DATABASE"
    echo -e "MYSQL_USER: $MYSQL_USER"
    echo -e "MYSQL_PASSWORD: $MYSQL_PASSWORD"
    echo -e "WORDPRESS_TABLE_PREFIX: $WORDPRESS_TABLE_PREFIX"
    echo -e "MYSQL_VERSION: $MYSQL_VERSION"
    echo -e "WORDPRESS_VERSION: $WORDPRESS_VERSION"
    echo -e "LOCAL_UID: $(id -u)"
    echo -e "LOCAL_GID: $(id -g)"
    echo ""
    
    # Confirmar creación
    read -p "¿Confirmas la creación del archivo .env con estos valores? (s/n): " confirm
    if [[ $confirm != [sS] ]]; then
        echo -e "${YELLOW}Operación cancelada por el usuario.${NC}"
        return 1
    fi
    
    # Crear archivo .env
    cat > "$ROOT_DIR/.env" << EOL
# MySQL Configuration
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=$MYSQL_DATABASE
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD

# WordPress Configuration
WORDPRESS_DB_HOST=db
WORDPRESS_DB_USER=$MYSQL_USER
WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
WORDPRESS_DB_NAME=$MYSQL_DATABASE
WORDPRESS_TABLE_PREFIX=$WORDPRESS_TABLE_PREFIX

# Container User IDs
LOCAL_UID=$(id -u)
LOCAL_GID=$(id -g)

# Version Control
MYSQL_VERSION=$MYSQL_VERSION
WORDPRESS_VERSION=$WORDPRESS_VERSION
EOL
    
    # Exportar variables para uso en el script
    export MYSQL_ROOT_PASSWORD
    export MYSQL_DATABASE
    export MYSQL_USER
    export MYSQL_PASSWORD
    export WORDPRESS_TABLE_PREFIX
    export MYSQL_VERSION
    export WORDPRESS_VERSION
    
    echo -e "${GREEN}✓ Archivo .env creado correctamente en $ROOT_DIR/.env${NC}"
    echo ""
    return 0
}

# Función para crear archivo .htaccess en WordPress
create_htaccess() {
    echo -e "${YELLOW}Creando archivo .htaccess...${NC}"
    
    # Crear archivo .htaccess
    cat > "$ROOT_DIR/wordpress/.htaccess" << EOL
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOL
    
    echo -e "${GREEN}✓ Archivo .htaccess creado correctamente${NC}"
    echo ""
}

# Función para modificar o crear wp-config.php
modify_wp_config() {
    # Verificar si el directorio wordpress existe
    if [ ! -d "$ROOT_DIR/wordpress" ]; then
        echo -e "${RED}El directorio wordpress no existe. Creándolo...${NC}"
        mkdir -p "$ROOT_DIR/wordpress"
    fi
    
    # Verificar si wp-config.php existe
    WP_CONFIG_FILE="$ROOT_DIR/wordpress/wp-config.php"
    
    if [ -f "$WP_CONFIG_FILE" ]; then
        echo -e "${YELLOW}Modificando wp-config.php existente...${NC}"
        
        # Realizar una copia de seguridad del archivo original
        cp "$WP_CONFIG_FILE" "${WP_CONFIG_FILE}.bak"
        echo -e "${YELLOW}Copia de seguridad creada en ${WP_CONFIG_FILE}.bak${NC}"
        
        # Modificar la configuración de la base de datos
        echo -e "${YELLOW}Modificando configuración de la base de datos...${NC}"
        
        # Método más seguro para modificar los defines DB_*
        # 1. DB_USER
        sed -i "/define.*DB_USER/c\define( 'DB_USER', getenv('MYSQL_USER') ?: '' );" "$WP_CONFIG_FILE"
        
        # 2. DB_PASSWORD
        sed -i "/define.*DB_PASSWORD/c\define( 'DB_PASSWORD', getenv('MYSQL_PASSWORD') ?: '' );" "$WP_CONFIG_FILE"
        
        # 3. DB_HOST
        sed -i "/define.*DB_HOST/c\define( 'DB_HOST', 'db' );" "$WP_CONFIG_FILE"
        
        # 4. DB_NAME - Opcional, pero recomendado para completar la configuración
        sed -i "/define.*DB_NAME/c\define( 'DB_NAME', getenv('MYSQL_DATABASE') ?: '' );" "$WP_CONFIG_FILE"
        
        echo -e "${GREEN}✓ Configuración de la base de datos actualizada${NC}"
        
        # Verificar si ya contiene la configuración para localhost
        if grep -q "HTTP_HOST.*localhost:8000" "$WP_CONFIG_FILE"; then
            echo -e "${GREEN}✓ La configuración para localhost:8000 ya existe en wp-config.php${NC}"
        else
            # Buscar la posición correcta para insertar el código - justo después de <?php
            # pero respetando si ya hay comentarios o definiciones de WP_CACHE antes
            if grep -q "WP_CACHE.*true" "$WP_CONFIG_FILE"; then
                # Si hay WP_CACHE, insertamos después de esa línea
                sed -i '/WP_CACHE.*true/a \
// Configuración para entorno local\
if ($_SERVER["HTTP_HOST"] === "localhost:8000") {\
    define("WP_HOME", "http://localhost:8000");\
    define("WP_SITEURL", "http://localhost:8000");\
}' "$WP_CONFIG_FILE"
            else
                # Si no hay WP_CACHE, insertamos después de <?php
                sed -i '/<?php/a \
// Configuración para entorno local\
if ($_SERVER["HTTP_HOST"] === "localhost:8000") {\
    define("WP_HOME", "http://localhost:8000");\
    define("WP_SITEURL", "http://localhost:8000");\
}' "$WP_CONFIG_FILE"
            fi
            
            echo -e "${GREEN}✓ Configuración para localhost:8000 añadida a wp-config.php${NC}"
        fi
        
        echo -e "${GREEN}✓ wp-config.php modificado correctamente${NC}"
    else
        echo -e "${YELLOW}No se encontró wp-config.php. Creando uno personalizado...${NC}"
        
        # Cargar variables del archivo .env
        if [ -f "$ROOT_DIR/.env" ]; then
            source "$ROOT_DIR/.env"
        else
            echo -e "${RED}Archivo .env no encontrado. Por favor, crea primero el archivo .env.${NC}"
            return 1
        fi
        
        # Generar salts aleatorios
        echo -e "${YELLOW}Generando salts aleatorios...${NC}"
        SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
        
        # Crear wp-config.php personalizado
        cat > "$WP_CONFIG_FILE" << EOL
<?php
// Configuración para entorno local
if (\$_SERVER["HTTP_HOST"] === "localhost:8000") {
    define("WP_HOME", "http://localhost:8000");
    define("WP_SITEURL", "http://localhost:8000");
}

/**
 * The base configuration for WordPress
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', getenv('MYSQL_DATABASE') ?: '' );

/** Database username */
define( 'DB_USER', getenv('MYSQL_USER') ?: '' );

/** Database password */
define( 'DB_PASSWORD', getenv('MYSQL_PASSWORD') ?: '' );

/** Database hostname */
define( 'DB_HOST', 'db' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
${SALTS}

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix = '${WORDPRESS_TABLE_PREFIX:-wp_}';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );

/* Add any custom values between this line and the "stop editing" line. */
define( 'FS_METHOD', 'direct' );
define( 'AUTOSAVE_INTERVAL', 300 );
define( 'WP_POST_REVISIONS', 3 );
define( 'EMPTY_TRASH_DAYS', 7 );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOL
        
        echo -e "${GREEN}✓ wp-config.php creado correctamente con la configuración para Docker${NC}"
    fi
    
    echo ""
}

# Función para iniciar los contenedores Docker
start_containers() {
    echo -e "${YELLOW}Iniciando contenedores Docker...${NC}"
    
    # Levantar contenedores en segundo plano
    docker compose up -d
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error al iniciar los contenedores. Verifica que Docker esté instalado y funcionando.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Contenedores iniciados correctamente${NC}"
    echo ""
    
    # Esperar a que MySQL esté listo
    echo -e "${YELLOW}⏳ Esperando a que MySQL esté listo...${NC}"
    
    until docker exec wp_db mysqladmin ping -h "127.0.0.1" --silent &> /dev/null; do
        echo -n "."
        sleep 2
    done
    
    echo -e "${GREEN}✓ MySQL está listo${NC}"
    echo ""
    
    # Mostrar URL de acceso
    echo -e "${GREEN}🎉 ¡Entorno listo! Accede a WordPress en http://localhost:8000${NC}"
    echo ""
}

# Función para parar los contenedores Docker
stop_containers() {
    echo -e "${YELLOW}Deteniendo contenedores Docker...${NC}"
    
    docker compose down
    
    echo -e "${GREEN}✓ Contenedores detenidos correctamente${NC}"
    echo ""
}

# Función para reiniciar los contenedores Docker
restart_containers() {
    echo -e "${YELLOW}Reiniciando contenedores Docker...${NC}"
    
    docker compose restart
    
    echo -e "${GREEN}✓ Contenedores reiniciados correctamente${NC}"
    echo ""
}

# Menú principal
show_menu() {
    show_banner
    echo -e "${BLUE}=== Menú Principal ===${NC}"
    echo -e "  ${YELLOW}1.${NC} Crear archivo .env"
    echo -e "  ${YELLOW}2.${NC} Configurar archivos WordPress"
    echo -e "  ${YELLOW}3.${NC} Iniciar contenedores"
    echo -e "  ${YELLOW}4.${NC} Detener contenedores"
    echo -e "  ${YELLOW}5.${NC} Reiniciar contenedores"
    echo -e "  ${YELLOW}6.${NC} Configuración completa (pasos 1-3)"
    echo -e "  ${YELLOW}0.${NC} Salir"
    echo ""
    read -p "Selecciona una opción: " option
    
    case $option in
        1) create_env_file; press_enter_to_continue ;;
        2) create_directories; create_htaccess; modify_wp_config; press_enter_to_continue ;;
        3) start_containers; press_enter_to_continue ;;
        4) stop_containers; press_enter_to_continue ;;
        5) restart_containers; press_enter_to_continue ;;
        6) 
            create_directories
            if create_env_file; then
                create_htaccess
                modify_wp_config
                start_containers
            fi
            press_enter_to_continue
            ;;
        0) exit 0 ;;
        *) echo -e "${RED}Opción inválida${NC}"; press_enter_to_continue ;;
    esac
}

# Función para "Presiona Enter para continuar"
press_enter_to_continue() {
    echo ""
    read -p "Presiona Enter para continuar..."
    show_menu
}

# Comprobar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker no está instalado. Por favor, instala Docker antes de continuar.${NC}"
    exit 1
fi

# Comprobar si Docker Compose está instalado
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose no está instalado. Por favor, instala Docker Compose antes de continuar.${NC}"
    exit 1
fi

# Iniciar menú
show_menu