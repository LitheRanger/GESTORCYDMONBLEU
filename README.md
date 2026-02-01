# GESTORCYDMONBLEU
Gestor de cambios y devoluciones 

## Despliegue en Render

### Prerrequisitos
1. Crear una base de datos PostgreSQL Managed en Render.
2. Obtener la URL de conexión de la base de datos (DATABASE_URL).

### Configuración de Variables de Entorno
En la configuración del servicio web en Render, añade las siguientes variables de entorno:

- **DATABASE_URL** (requerido): URL de conexión a PostgreSQL proporcionada por Render.
- **SECRET_KEY** (requerido): Clave secreta para Flask (genera una clave aleatoria segura).
- **WEBHOOK_API_KEY** (opcional): Clave para proteger webhooks entrantes.
- **RUN_SQL_MIGRATIONS** (opcional): Si se establece en `true`, el script `start.sh` ejecutará el archivo `MIGRATION_GESTORCYDMONBLEU.sql` usando `psql` antes de iniciar la aplicación.

### Migraciones de Base de Datos

El script `start.sh` admite dos formas de inicializar la base de datos:

#### Opción 1: Migraciones SQL automáticas (Recomendado para producción)
Establece la variable de entorno `RUN_SQL_MIGRATIONS=true` en Render. Durante el despliegue, `start.sh` ejecutará automáticamente el archivo `MIGRATION_GESTORCYDMONBLEU.sql` usando el cliente `psql`.

**Nota importante**: El entorno de ejecución de Render debe proporcionar el cliente `psql`. Si no está disponible, consulta las instrucciones alternativas a continuación.

#### Opción 2: db.create_all() (Fallback)
Si `RUN_SQL_MIGRATIONS` no está establecido o es `false`, `start.sh` ejecutará `db.create_all()` de SQLAlchemy para crear las tablas necesarias. Esta es una solución alternativa que funciona sin necesidad de `psql`.

#### Instrucciones alternativas si psql no está disponible
Si el entorno de Render no proporciona `psql`, puedes ejecutar las migraciones manualmente:

1. **Desde tu máquina local**:
   ```bash
   DATABASE_URL="postgresql://..." ./run_migrations.sh
   ```

2. **Desde un pipeline CI/CD**: Ejecuta el script `run_migrations.sh` en un paso previo al despliegue.

3. **Usar la interfaz de Render**: Ejecuta el contenido de `MIGRATION_GESTORCYDMONBLEU.sql` directamente en la consola de PostgreSQL de Render.

### Pruebas locales

#### Crear tablas localmente con db.create_all()
```bash
export DATABASE_URL="postgresql://usuario:password@localhost/dbname"
python - <<'PY'
from app import db, app
with app.app_context():
    db.create_all()
print("DB initialized (db.create_all completed).")
PY
```

#### Ejecutar migraciones SQL localmente
```bash
DATABASE_URL="postgresql://usuario:password@localhost/dbname" ./run_migrations.sh
```

#### Iniciar la aplicación localmente
```bash
export DATABASE_URL="postgresql://usuario:password@localhost/dbname"
export SECRET_KEY="tu-clave-secreta"
gunicorn app:app --bind 0.0.0.0:5000
```

### Validación del despliegue
1. Verifica que el servicio se inicie correctamente en los logs de Render.
2. Si usas `RUN_SQL_MIGRATIONS=true`, verifica en los logs que aparece "Running SQL migrations from MIGRATION_GESTORCYDMONBLEU.sql".
3. Si no usas `RUN_SQL_MIGRATIONS`, verifica en los logs que aparece "Running SQLAlchemy db.create_all()".
4. Accede a la URL del servicio para confirmar que la aplicación responde correctamente.
