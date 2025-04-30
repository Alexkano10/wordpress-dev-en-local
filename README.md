# 🐳 Entorno Local WordPress con Docker Compose 

## 📖 Descripción

Este repositorio proporciona un entorno de desarrollo local para WordPress usando Docker Compose, diseñado para que desarrolladores puedan empezar a trabajar sin instalaciones complejas.

### ✨ Características principales

- **Persistencia de datos**: Base de datos MySQL almacenada en ./database
- **Hot-reload**: Cambios en tiempo real de código y assets desde ./wordpress 
- **Configuración sencilla**: Levantado con un único script ./scripts/start.sh
- **Aislamiento completo**: Todo el entorno está en contenedores

## 📚 Documentación

Para instrucciones detalladas y guías paso a paso, visita:
[Documentación completa del proyecto](https://alexkano10.github.io/my-documentation/projects/wordpress-dev-en-local.html)

## ⚙️ Requisitos previos

- Ubuntu / macOS / Windows (con WSL2)
- [Docker CE](https://docs.docker.com/engine/install/) ≥ 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) v2 (docker compose)
- Git

## 🚀 Instalación y arranque

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/Alexkano10/wordpress-dev-en-local.git
cd wordpress-dev-en-local
```

### Paso 2: Configurar variables de entorno

```bash
cp .env.example .env
```

Edita el archivo .env para definir:
- MYSQL_ROOT_PASSWORD - Contraseña para el usuario root de MySQL
- MYSQL_DATABASE - Nombre de la base de datos
- MYSQL_USER - Usuario de MySQL para WordPress
- MYSQL_PASSWORD - Contraseña del usuario MySQL
- WORDPRESS_TABLE_PREFIX - Prefijo para tablas de WordPress (wp_ por defecto)
- MYSQL_VERSION - Versión de MySQL/MariaDB a utilizar
- WORDPRESS_VERSION - Versión de WordPress a utilizar

### Paso 3: Iniciar el entorno

```bash
./scripts/start.sh
```

### Paso 4: Acceder a WordPress

Abre tu navegador y navega a:
http://localhost:8000

## 🛠 Uso diario

### Gestión de servicios

```bash
# Detener todos los servicios
docker compose down

# Reiniciar solo WordPress
docker compose up -d wordpress

# Forzar reconstrucción (después de cambiar Dockerfile o dependencias)
docker compose up -d --build
```

### Acceso a logs

```bash
# Ver logs de todos los servicios
docker compose logs

# Ver logs solo de WordPress
docker compose logs wordpress

# Ver logs en tiempo real
docker compose logs -f
```

## 🔧 Configuración avanzada

### Variables de entorno

El archivo .env controla la configuración del entorno. Las variables disponibles son:

```dotenv
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_password
WORDPRESS_TABLE_PREFIX=wp_
MYSQL_VERSION=8.0
WORDPRESS_VERSION=latest
```

### Estructura de directorios

```
wordpress-dev-en-local/
├── database/                # Persistencia de MySQL
├── wordpress/               # Código fuente de WordPress
├── docker-compose.yml       # Configuración de servicios
├── .env.example             # Plantilla de variables de entorno
├── .env                     # Variables de entorno (no versionado)
└── scripts/
    └── start.sh             # Script de inicio
```

## 💻 Entorno de desarrollo recomendado

- **Editor**: VSCode con extensiones PHP y WordPress
- **Navegador**: Chrome/Firefox con DevTools para desarrollo web
- **Terminal**: iTerm2 (macOS) o Windows Terminal (Windows)
- **Git GUI**: GitKraken o Sourcetree (opcional)

## ⚠️ Solución de problemas

| Problema | Solución |
|----------|----------|
| Variables no definidas | Asegúrate de tener ./.env correctamente copiado desde .env.example |
| Permisos de carpetas | Ejecuta `chown -R $UID:$UID database wordpress` |
| Hot-reload no funciona | Verifica que estás editando dentro de ./wordpress y recarga el navegador |
| Puerto en uso | Cambia 8000:80 en docker-compose.yml y recrea los servicios |
| Error de conexión a MySQL | Comprueba que las credenciales en .env coinciden con las de WordPress |
| Contenedor crashea | Ejecuta `docker compose logs [servicio]` para ver errores detallados |

## 🤝 Contribuciones

1. Haz un fork del repositorio
2. Crea una rama para tu feature o bugfix (`git checkout -b feature/amazing-feature`)
3. Realiza tus cambios y haz commit (`git commit -m 'Add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - consulta el archivo LICENSE para más detalles.

## 📞 Soporte

Para problemas, preguntas o sugerencias, por favor [abre un issue](https://github.com/Alexkano10/wordpress-dev-en-local/issues/new) en este repositorio.

---

¡Feliz desarrollo con WordPress! 🚀