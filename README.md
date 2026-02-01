# GESTORCYDMONBLEU
Gestor de cambios y devoluciones con integración de pagos y shipping

## Descripción
Sistema de gestión de cambios y devoluciones con integración de:
- Pagos via Stripe
- Envíos via FedEx
- Base de datos PostgreSQL
- Autenticación de usuarios con roles

## Despliegue en Render

### Requisitos previos
1. Cuenta en [Render.com](https://render.com)
2. Repositorio conectado a Render

### Pasos para el despliegue

#### 1. Crear base de datos PostgreSQL
1. En el dashboard de Render, crear un nuevo **PostgreSQL** (Managed Database)
2. Seleccionar el plan (Free o el que necesites)
3. Una vez creada, copiar la **Internal Database URL** (formato: `postgresql://user:pass@host/db`)

#### 2. Configurar el servicio Web
1. Crear un nuevo **Web Service** en Render
2. Conectar el repositorio `GESTORCYDMONBLEU`
3. Configurar las siguientes opciones:
   - **Name**: `gestorcydmonbleu-backend` (o el nombre que prefieras)
   - **Environment**: `Python`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `bash start.sh`

#### 3. Configurar variables de entorno
En la sección **Environment** del servicio, añadir las siguientes variables:

**Variables obligatorias:**
- `DATABASE_URL`: La Internal Database URL de tu PostgreSQL (ej: `postgresql://user:pass@host/db`)
- `SECRET_KEY`: Una clave secreta segura y única para Flask sessions. **IMPORTANTE**: Debe ser única por entorno y nunca debe estar en control de versiones. Generar con `python -c "import secrets; print(secrets.token_hex(32))"`. Usar una clave débil o compartida compromete la seguridad de las sesiones.

**Variables opcionales:**
- `WEBHOOK_API_KEY`: Clave para proteger webhooks (genera una si necesitas webhooks)
- `WORKERS`: Número de workers de gunicorn (default: 2, recomendado: `2 * CPU_CORES + 1`)
- `THREADS`: Número de threads por worker (default: 2, recomendado: 2-4)
- Cualquier otra variable que necesite tu aplicación

#### 4. Desplegar
1. Hacer clic en **Manual Deploy** → **Deploy latest commit**
2. El script `start.sh` se encargará de:
   - Inicializar las tablas de la base de datos usando `db.create_all()`
   - Iniciar el servidor gunicorn

#### 5. (Opcional) Ejecutar SQL manual
Si prefieres usar el script SQL en lugar de `db.create_all()`:
1. Conectarte a la base de datos usando el **External Database URL**
2. Ejecutar el archivo `MIGRATION_GESTORCYDMONBLEU.sql`

**Nota**: El script `start.sh` ya ejecuta `db.create_all()` automáticamente, por lo que no es necesario ejecutar SQL manualmente en la mayoría de casos.

### Verificar el despliegue
1. Una vez desplegado, visitar la URL del servicio (ej: `https://gestorcydmonbleu-backend.onrender.com`)
2. Verificar que la aplicación está funcionando correctamente
3. Revisar los logs en caso de errores

## Desarrollo local

### Instalación
```bash
# Instalar dependencias
pip install -r requirements.txt
```

### Configurar base de datos local
```bash
# Configurar variable de entorno
export DATABASE_URL=postgresql://user:password@localhost/dbname

# Inicializar tablas
python -c "from app import db, app; with app.app_context(): db.create_all()"
```

### Ejecutar localmente
```bash
# Opción 1: Usando Flask development server
export SECRET_KEY=dev-secret-key  # ⚠️ SOLO para desarrollo local, nunca usar en producción
export DATABASE_URL=postgresql://user:password@localhost/dbname
flask run

# Opción 2: Usando el script de arranque (simula producción)
export SECRET_KEY=dev-secret-key  # ⚠️ SOLO para desarrollo local, nunca usar en producción
export DATABASE_URL=postgresql://user:password@localhost/dbname
export PORT=8000
bash start.sh
```

## Tecnologías utilizadas
- **Backend**: Flask 3.0.0
- **Base de datos**: PostgreSQL con SQLAlchemy
- **Servidor**: Gunicorn
- **Pagos**: Stripe
- **Envíos**: FedEx 
