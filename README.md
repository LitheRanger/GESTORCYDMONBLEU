# GESTORCYDMONBLEU
Gestor de cambios y devoluciones

## Descripción

Sistema de gestión de cambios y devoluciones con integración de pagos (Stripe) y envíos (FedEx). Aplicación Flask con base de datos PostgreSQL.

## Despliegue en Render

### Requisitos Previos

1. Cuenta en [Render](https://render.com)
2. Base de datos PostgreSQL (Render Managed Postgres o externa)

### Configuración de Base de Datos

#### Opción 1: Crear Managed Postgres en Render

1. En el dashboard de Render, crear un nuevo **PostgreSQL** service
2. Seleccionar el plan (Free tier disponible)
3. Una vez creado, copiar la **Internal Database URL** o **External Database URL**

#### Opción 2: Conectar a Base de Datos Externa

Asegurar que la base de datos PostgreSQL es accesible y obtener la cadena de conexión en formato:
```
postgresql://username:password@host:port/database?sslmode=require
```

### Desplegar el Servicio Web

1. **Fork o clonar este repositorio**

2. **Crear un nuevo Web Service en Render:**
   - Conectar con tu repositorio GitHub
   - Seleccionar la rama `main` (o la rama deseada)
   - Render detectará automáticamente `render.yaml`

3. **Configurar Variables de Entorno:**

   En el dashboard del servicio, agregar las siguientes variables de entorno:

   | Variable | Descripción | Ejemplo |
   |----------|-------------|---------|
   | `DATABASE_URL` | URL de conexión a PostgreSQL | `postgresql://user:pass@host:5432/db?sslmode=require` |
   | `SECRET_KEY` | Clave secreta para Flask sessions | `tu-clave-secreta-segura` |
   | `WEBHOOK_API_KEY` | API Key para proteger webhooks | `webhook-api-key-segura` |
   | `RUN_SQL_MIGRATIONS` | (Opcional) Ejecutar migraciones SQL en inicio | `true` o dejar sin configurar |

   **Importante:** No incluir credenciales en el código fuente. Todas las claves deben configurarse como variables de entorno.

4. **Elegir Método de Inicialización de Base de Datos:**

   #### Método 1: SQLAlchemy Auto-Create (Recomendado para desarrollo)
   
   - **No configurar** `RUN_SQL_MIGRATIONS` (o establecer en `false`)
   - El script `start.sh` ejecutará automáticamente `db.create_all()` al iniciar
   - Las tablas se crearán basándose en los modelos SQLAlchemy en `app.py`

   #### Método 2: Migraciones SQL (Recomendado para producción)
   
   - Configurar `RUN_SQL_MIGRATIONS=true` en las variables de entorno
   - El script `start.sh` ejecutará `MIGRATION_GESTORCYDMONBLEU.sql` usando `psql`
   - Este archivo SQL contiene el esquema completo y está en el repositorio

5. **Desplegar:**
   - Render ejecutará el `buildCommand` para instalar dependencias
   - Luego ejecutará `startCommand` (bash start.sh) que:
     - Inicializa la base de datos (método elegido)
     - Inicia Gunicorn en el puerto especificado por Render

### Migraciones Locales (Desarrollo)

#### Ejecutar SQLAlchemy create_all localmente:

```bash
export DATABASE_URL='postgresql://user:pass@localhost:5432/dbname'
export SECRET_KEY='dev-secret-key'
python -c "from app import db, app; app.app_context().push(); db.create_all(); print('DB inicializada')"
```

#### Ejecutar migraciones SQL localmente:

```bash
export DATABASE_URL='postgresql://user:pass@localhost:5432/dbname'
bash run_migrations.sh
```

O directamente con psql:

```bash
psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
```

### Crear Usuarios Iniciales

Después del primer despliegue, crear usuarios accediendo a la ruta `/crear-usuarios`:

```
https://tu-app.onrender.com/crear-usuarios
```

Esto creará usuarios de prueba:
- **admin** / **1234** (rol: admin)
- **soporte** / **1234** (rol: soporte)

**Importante:** Cambiar las contraseñas en producción.

### Verificación Post-Despliegue

1. Verificar que el servicio está corriendo: `https://tu-app.onrender.com`
2. Acceder al login: `https://tu-app.onrender.com/login`
3. Verificar logs en el dashboard de Render para cualquier error

## Variables de Entorno Completas

| Variable | Requerida | Descripción | Valor por Defecto |
|----------|-----------|-------------|-------------------|
| `DATABASE_URL` | ✅ Sí | URL de conexión PostgreSQL | Ninguno (debe configurarse) |
| `SECRET_KEY` | ✅ Sí | Clave secreta para Flask | `dev-secret-key` (solo desarrollo) |
| `WEBHOOK_API_KEY` | ✅ Sí | API Key para webhooks | `webhook-demo-key` (solo desarrollo) |
| `RUN_SQL_MIGRATIONS` | ❌ No | Ejecutar SQL al inicio | `false` |
| `PORT` | ❌ No | Puerto del servidor (Render lo configura automáticamente) | `8000` |

## Arquitectura

- **Framework:** Flask 3.0.0
- **ORM:** Flask-SQLAlchemy 3.1.1
- **Base de Datos:** PostgreSQL (psycopg2-binary 2.9.9)
- **Servidor Web:** Gunicorn 21.2.0
- **Integraciones:** Stripe (pagos), FedEx (envíos)

## Desarrollo Local

### Instalación

```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
export DATABASE_URL='postgresql://localhost/gestorcydmonbleu'
export SECRET_KEY='dev-secret-key'
export WEBHOOK_API_KEY='webhook-demo-key'

# Inicializar base de datos
python -c "from app import db, app; app.app_context().push(); db.create_all()"

# Crear usuarios
python -c "from app import app; import urllib.request; urllib.request.urlopen('http://localhost:5000/crear-usuarios')"
```

### Ejecutar en Desarrollo

```bash
python app.py
# O con gunicorn:
gunicorn app:app --bind 0.0.0.0:8000 --reload
```

### Ejecutar con Script de Producción

```bash
bash start.sh
```

## Endpoints Principales

- `POST /webhook/return-requests` - Recibir solicitudes desde CYDMONBLEU
- `GET /` - Dashboard (requiere login)
- `GET /login` - Página de login
- `POST /return-request/<id>/approve` - Aprobar solicitud
- `POST /return-request/<id>/reject` - Rechazar solicitud
- `GET /api/return-requests` - API listar solicitudes

## Seguridad

- Las contraseñas se almacenan hasheadas (Werkzeug security)
- Webhooks protegidos con API Key
- Variables sensibles mediante variables de entorno
- Soporte SSL/TLS para conexión a base de datos

## Soporte

Para problemas o preguntas, abrir un issue en el repositorio de GitHub. 
