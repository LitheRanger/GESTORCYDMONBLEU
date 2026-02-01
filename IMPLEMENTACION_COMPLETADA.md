Instalar las dependencias necesarias (ya que hemos actualizado a SQLAlchemy moderno):

```bash
pip install flask flask-sqlalchemy werkzeug psycopg2-binary python-dotenv
```

Si usas requirements.txt:

```bash
pip install -r requirements.txt
```

## 🚀 Pasos de Implementación

### 1. **Actualizar app.py** ✅ HECHO
Ya se ha reemplazado con `IMPROVED_GESTORCYDMONBLEU_APP.py`

### 2. **Actualizar templates** ✅ HECHO
- `dashboard.html` → Kanban mejorado con campos de ReturnRequest
- `detalle_solicitud.html` → Nuevo template para ver detalles + historial

### 3. **Ejecutar migración SQL**

Opción A: Desde PostgreSQL directo
```bash
psql "postgresql://neondb_owner:npg_O1toy9DsgBRa@ep-patient-dew-ahpacjaq-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require" -f MIGRATION_GESTORCYDMONBLEU.sql
```

Opción B: Desde Flask (recomendado en desarrollo)
```python
from app import app, db
with app.app_context():
    db.create_all()
```

Opción C: Acceder a rutas de inicialización
```
http://localhost:5000/init-db          # Crear tablas
http://localhost:5000/crear-usuarios   # Crear usuarios demo
```

### 4. **Variables de Entorno**

Crear un archivo `.env`:
```env
SECRET_KEY=tu-secret-key-segura
DATABASE_URL=postgresql://neondb_owner:npg_O1toy9DsgBRa@ep-patient-dew-ahpacjaq-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require
WEBHOOK_API_KEY=webhook-demo-key
FLASK_ENV=production
```

### 5. **Reiniciar la aplicación**

```bash
python app.py
```

O en Render:
1. Commit y push a GitHub
2. Render automáticamente redeploy

## 📝 Cambios Principales Realizados

### Models
- ✅ `Solicitud` → `ReturnRequest` (estructura mejorada)
- ✅ `ReturnRequestHistorial` (nuevo, para auditoría)

### Campos nuevos en ReturnRequest
- `payment_status` (pending, paid, failed)
- `stripe_session_id` (para verificar pagos)
- `carrier` (FEDEX, UPS)
- `tracking_number` (número de envío)
- `label_base64` (etiqueta PDF en base64)
- `label_mime` (tipo MIME)
- `contact_phone` (teléfono del cliente)
- `items_json` (artículos con imágenes)
- `files_json` (archivos adjuntos)

### Rutas nuevas
- `GET /api/return-requests` - Listar solicitudes con filtros
- `GET /api/return-requests/<id>/historial` - Historial de acciones
- `POST /webhook/return-requests` - Webhook desde CYDMONBLEU
- `POST /return-request/<id>/approve` - Aprobar
- `POST /return-request/<id>/reject` - Rechazar

## 🔗 Integración CYDMONBLEU

El webhook espera un payload como este:

```json
{
    "request_id": "REQ-12345",
    "order_id": "#1001",
    "cliente": {
        "nombre": "Juan",
        "email": "juan@example.com",
        "phone": "+34600000000"
    },
    "tipo": "cambio",
    "items": [...],
    "razon": "No me gusta el color",
    "amount": 150.00,
    "payment_status": "paid",
    "stripe_session_id": "cs_live_xxxxx",
    "carrier": "FEDEX",
    "tracking_number": "7684294823",
    "label_base64": "JVBERi0xLjQK...",
    "label_mime": "application/pdf"
}
```

Headers requeridos:
```
X-API-KEY: webhook-demo-key
Content-Type: application/json
```

## 🧪 Test del Webhook

```bash
curl -X POST http://localhost:5000/webhook/return-requests \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: webhook-demo-key" \
  -d '{
    "request_id":"REQ-TEST-001",
    "order_id":"#9999",
    "cliente":{"nombre":"Test User","email":"test@example.com"},
    "tipo":"devolucion",
    "items":[],
    "razon":"Test reason",
    "amount":150.00,
    "payment_status":"paid"
  }'
```

## 📊 Base de Datos

Tabla principal: `return_requests`
- Índices en: estado, order_id, payment_status, created_at, request_id

Tabla historial: `return_request_historial`
- Auditoría de todas las acciones realizadas

Vistas SQL útiles:
- `v_return_requests_summary` - Resumen de solicitudes por estado
- `v_return_requests_with_latest_action` - Solicitudes con última acción

## ✅ Checklist Final

- [ ] app.py actualizado ✅
- [ ] Templates actualizados ✅
- [ ] MIGRATION_GESTORCYDMONBLEU.sql creado ✅
- [ ] Variables de entorno configuradas
- [ ] Migración SQL ejecutada
- [ ] Usuarios creados (admin/1234, soporte/1234)
- [ ] Webhook URL configurada en CYDMONBLEU
- [ ] Test de webhook realizado
- [ ] Solicitud aparece en Kanban
- [ ] Approve/Reject funcionan

## 📞 Soporte

Problema | Solución
---------|----------
Tablas no existen | Acceder a /init-db
Usuarios no existen | Acceder a /crear-usuarios
Webhook 403 | Verificar X-API-KEY
Error de conexión BD | Verificar DATABASE_URL en .env
Templates no encontrados | Verificar que detalle_solicitud.html existe en templates/

## 🎉 ¡Implementación completa!

Todos los cambios descritos en GESTORCYDMONBLEU_UPGRADE_GUIDE.md han sido aplicados.
La aplicación está lista para recibir solicitudes desde CYDMONBLEU.
