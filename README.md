# GESTORCYDMONBLEU
Gestor de cambios y devoluciones 

## Despliegue en Render

Este repositorio está configurado para desplegarse fácilmente en Render como servicio web Python con soporte para migraciones SQL opcionales.

### Configuración inicial

#### 1. Crear Base de Datos Postgres en Render

1. Accede a tu [Dashboard de Render](https://dashboard.render.com/)
2. Crea un nuevo servicio PostgreSQL (Render Managed Postgres)
3. Copia la **Internal Database URL** (formato: `postgresql://...`)

#### 2. Crear Servicio Web

1. Conecta tu repositorio GitHub a Render
2. Crea un nuevo **Web Service**
3. Render detectará automáticamente el archivo `render.yaml`

#### 3. Configurar Variables de Entorno

En la configuración del servicio web, añade las siguientes variables de entorno:

**Variables Requeridas:**
- `DATABASE_URL`: URL de conexión a PostgreSQL (la que copiaste del paso 1)
- `SECRET_KEY`: Clave secreta para Flask (genera una aleatoria, ej: `python -c "import secrets; print(secrets.token_hex(32))"`)

**Variables Opcionales:**
- `WEBHOOK_API_KEY`: Clave para proteger webhooks (por defecto: `webhook-demo-key`)
- `RUN_SQL_MIGRATIONS`: Establece en `true` para ejecutar migraciones SQL automáticamente (ver sección siguiente)

### Migraciones de Base de Datos

Este proyecto soporta dos métodos para inicializar/migrar la base de datos:

#### Opción 1: Migraciones SQL Automáticas (Recomendado para producción)

Para ejecutar el archivo `MIGRATION_GESTORCYDMONBLEU.sql` automáticamente al inicio:

1. Establece la variable de entorno `RUN_SQL_MIGRATIONS=true` en tu servicio Render
2. El script `start.sh` ejecutará las migraciones SQL usando `psql` antes de iniciar el servidor
3. Esto es ideal cuando tienes un esquema SQL completo y quieres control total sobre la estructura de la base de datos

**Nota:** Asegúrate de que la imagen de Render incluya la utilidad `psql`. Si no está disponible, considera ejecutar las migraciones manualmente (ver más abajo) o usar el método alternativo.

#### Opción 2: SQLAlchemy db.create_all() (Fallback)

Si `RUN_SQL_MIGRATIONS` no está establecido o es `false`:

1. El sistema usará `db.create_all()` de SQLAlchemy para crear las tablas automáticamente
2. Esto es más simple pero puede no capturar todos los detalles del esquema SQL
3. Es útil para desarrollo y pruebas rápidas

### Migraciones Manuales

Si prefieres ejecutar las migraciones manualmente:

#### Desde tu máquina local:

```bash
# Establece la variable DATABASE_URL con la conexión a tu base de datos
export DATABASE_URL="postgresql://usuario:contraseña@host:puerto/database"

# Opción 1: Usar el script helper
bash run_migrations.sh

# Opción 2: Ejecutar psql directamente
psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
```

#### Desde Render Shell:

1. Abre el Shell de tu servicio web en Render
2. Ejecuta: `bash run_migrations.sh`

### Pruebas Locales

Para probar el sistema localmente antes de desplegar:

#### 1. Instalar dependencias:

```bash
pip install -r requirements.txt
```

#### 2. Configurar variables de entorno:

```bash
export DATABASE_URL="postgresql://localhost/tu_base_datos"
export SECRET_KEY="tu-clave-secreta-local"
export WEBHOOK_API_KEY="tu-clave-webhook-local"
```

#### 3. Inicializar base de datos (opción manual):

```bash
# Con SQLAlchemy
python -c "from app import db, app; \
with app.app_context(): \
    db.create_all(); \
    print('Base de datos inicializada')"

# O con migraciones SQL
export RUN_SQL_MIGRATIONS=true
psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
```

#### 4. Iniciar el servidor:

```bash
# Usando start.sh (simula Render)
export PORT=8000
bash start.sh

# O directamente con gunicorn
gunicorn app:app --bind 0.0.0.0:8000 --workers 2 --threads 2
```

#### 5. Probar el inicio con migraciones:

```bash
# Test 1: Sin migraciones SQL (usa db.create_all)
export DATABASE_URL="postgresql://localhost/test_db"
unset RUN_SQL_MIGRATIONS
bash start.sh

# Test 2: Con migraciones SQL
export DATABASE_URL="postgresql://localhost/test_db"
export RUN_SQL_MIGRATIONS=true
bash start.sh
```

### Solución de Problemas

**Error: "psql: command not found"**
- La imagen de Render no incluye psql por defecto
- Solución: Ejecuta las migraciones manualmente desde tu máquina local o usa `RUN_SQL_MIGRATIONS=false` para usar SQLAlchemy

**Error: "DATABASE_URL no está definido"**
- Asegúrate de haber configurado la variable `DATABASE_URL` en las variables de entorno de Render
- Verifica que apunta a tu instancia de PostgreSQL en Render

**Tablas no se crean correctamente**
- Si usas `RUN_SQL_MIGRATIONS=true`, revisa los logs de inicio para ver errores en las migraciones SQL
- Si usas `db.create_all()`, asegúrate de que los modelos en `app.py` están correctamente definidos

### Arquitectura de Inicio

El archivo `start.sh` realiza las siguientes acciones en orden:

1. **Verificación de variables**: Comprueba si `RUN_SQL_MIGRATIONS` está activado
2. **Inicialización de DB**: 
   - Si `RUN_SQL_MIGRATIONS=true`: Ejecuta `MIGRATION_GESTORCYDMONBLEU.sql` con psql
   - Si no: Ejecuta `db.create_all()` con SQLAlchemy
3. **Inicio del servidor**: Lanza gunicorn en el puerto especificado por Render (`$PORT`)

### Recursos Adicionales

- [Documentación de Render](https://render.com/docs)
- [Render Managed PostgreSQL](https://render.com/docs/databases)
- [Flask en Render](https://render.com/docs/deploy-flask)

