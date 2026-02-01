# 🔌 ARQUITECTURA TÉCNICA DE INTEGRACIÓN

## Diagrama de Flujo Completo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CLIENTE WEB (CYDMONBLEU)                          │
│  Frontend React/Vue/HTML5 - Formulario de devolución + Pago Stripe         │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                ┌────────────────┴─────────────────┐
                │                                  │
        [1. Datos Solicitud]              [2. Pago Stripe]
                │                                  │
                ↓                                  ↓
        ┌─────────────────┐            ┌──────────────────┐
        │  CYDMONBLEU DB  │            │  Stripe API      │
        │  (MongoDB/SQL)  │            │  webhook.session │
        └─────────────────┘            └──────────────────┘
                │                                  │
                └────────────────┬─────────────────┘
                                 │
                    [3. Generar Guía FedEx]
                                 │
                                 ↓
                ┌────────────────────────────────┐
                │  FedEx API                     │
                │  label_base64 + tracking_number│
                └────────────────┬───────────────┘
                                 │
                    [4. WEBHOOK POST]
                    X-API-KEY + JSON
                                 │
                                 ↓
        ┌────────────────────────────────────────────────────────┐
        │                  FIREWALL / INTERNET                   │
        │          https://gestor-app.onrender.com               │
        └────────────────┬─────────────────────────────────────┘
                         │
                         ↓
        ┌────────────────────────────────────────────────────────┐
        │           GESTORCYDMONBLEU (Python/Flask)              │
        │  Servicio de gestión de devoluciones                  │
        ├────────────────────────────────────────────────────────┤
        │                                                        │
        │  @app.route('/webhook/return-requests', POST)         │
        │  ├─ Valida X-API-KEY                                  │
        │  ├─ Mapea datos al modelo ReturnRequest               │
        │  ├─ Crea registro en BD                               │
        │  ├─ Registra en historial (acción: pago_recibido)     │
        │  └─ Retorna 201 OK                                    │
        │                                                        │
        │  [5. ReturnRequest creado en DB]                      │
        │  [6. Historial: "pago_recibido"]                      │
        │                                                        │
        └────────────────┬─────────────────────────────────────┘
                         │
                         ↓
        ┌────────────────────────────────────────────────────────┐
        │          PostgreSQL/Neon (return_requests DB)          │
        │                                                        │
        │  Tabla: return_requests                               │
        │  ├─ id: 1                                             │
        │  ├─ request_id: REQ-12345                             │
        │  ├─ payment_status: paid                              │
        │  ├─ estado: pendiente                                 │
        │  └─ tracking_number: 7684294823                       │
        │                                                        │
        │  Tabla: return_request_historial                      │
        │  └─ accion: pago_recibido, usuario: sistema           │
        │                                                        │
        └────────────────┬─────────────────────────────────────┘
                         │
        ┌────────────────┴─────────────────┐
        │                                  │
        ↓                                  ↓
    [7. Dashboard]              [8. API JSON]
    
    Admin ve en Kanban:         CYDMONBLEU puede consultar:
    - Columna: Pendientes       GET /api/return-requests
    - Tarjeta: REQ-12345        Obtiene estado actual
    - Cliente: Juan             
    - Monto: $150
    - Tracking: 7684294823
    - Botones: Aprobar/Rechazar
        │
        └─────────────────────────────────────────────────┐
                                                          │
                                                [9. Acción: Aprobar]
                                                          │
                                                          ↓
                ┌──────────────────────────────────────────────────┐
                │  POST /return-request/1/approve                  │
                │  ├─ Valida autenticación (login)                │
                │  ├─ Valida rol (admin/soporte)                  │
                │  ├─ Actualiza: estado = "aprobado"              │
                │  ├─ Registra en historial                       │
                │  └─ Redirige a dashboard                        │
                └──────────────────────────────────────────────────┘
                         │
                         ↓
        ┌────────────────────────────────────────────────────────┐
        │       PostgreSQL (actualización de estado)             │
        │                                                        │
        │  UPDATE return_requests SET estado='aprobado'          │
        │  INSERT INTO historial accion='aprobado'               │
        │                                                        │
        └────────────────┬─────────────────────────────────────┘
                         │
        ┌────────────────┴─────────────────┐
        │                                  │
        ↓                                  ↓
    [10. Dashboard]         [11. API (opcional)]
    
    Solicitud se mueve      CYDMONBLEU verifica:
    a "Aprobadas"           GET /api/return-requests/1
    - Tarjeta cambia        Obtiene estado: "aprobado"
    - Verde en Kanban       Notifica a cliente
    - Muestra tracking
        │
        └──────────────────────────────────────────────┐
                                                       │
                                            [12. Email/SMS (opcional)]
                                            Notificación al cliente
                                            "Tu devolución fue aprobada"
```

---

## 📡 Endpoints y Comunicación

### **1. Webhook (CYDMONBLEU → GESTORCYDMONBLEU)**

```
POST /webhook/return-requests

REQUEST:
  Headers:
    Content-Type: application/json
    X-API-KEY: webhook-demo-key
  
  Body:
    {
      request_id, order_id, cliente, tipo,
      items, files, razon, amount,
      payment_status, stripe_session_id,
      carrier, tracking_number,
      label_base64, label_mime
    }

RESPONSE 201:
  {
    "status": "ok",
    "request_id": "REQ-12345",
    "id": 1
  }

RESPONSE 403:
  {
    "error": "Unauthorized"
  }

RESPONSE 400:
  {
    "error": "Error message"
  }
```

### **2. API - Listar Solicitudes**

```
GET /api/return-requests?estado=pendiente&payment_status=paid

REQUEST:
  Headers:
    Authorization: Basic admin:1234
    (o desde CYDMONBLEU con token)

RESPONSE 200:
  {
    "success": true,
    "total": 5,
    "data": [
      {
        "id": 1,
        "request_id": "REQ-12345",
        "order_id": "#1001",
        "contact_name": "Juan",
        "contact_email": "juan@example.com",
        "payment_status": "paid",
        "estado": "pendiente",
        "amount": 150.00,
        "tracking_number": "7684294823"
      }
    ]
  }
```

### **3. API - Ver Historial**

```
GET /api/return-requests/1/historial

REQUEST:
  Headers:
    Authorization: Basic admin:1234

RESPONSE 200:
  {
    "success": true,
    "request_id": "REQ-12345",
    "historial": [
      {
        "id": 1,
        "accion": "pago_recibido",
        "usuario": "sistema",
        "nota": "Webhook desde CYDMONBLEU",
        "metadata": {"payment_status": "paid"},
        "fecha": "2026-01-31T10:30:00"
      },
      {
        "id": 2,
        "accion": "aprobado",
        "usuario": "admin",
        "nota": "Aprobado",
        "metadata": {"monto": 150.0},
        "fecha": "2026-01-31T10:32:00"
      }
    ]
  }
```

---

## 🗄️ Estructura de Base de Datos

### **Tabla: return_requests**

```sql
CREATE TABLE return_requests (
  id SERIAL PRIMARY KEY,
  
  -- Identificadores
  request_id VARCHAR(50) UNIQUE NOT NULL,  -- REQ-12345
  order_id VARCHAR(50) NOT NULL,           -- #1001
  
  -- Cliente
  contact_name VARCHAR(150),               -- Juan
  contact_email VARCHAR(150),              -- juan@example.com
  contact_phone VARCHAR(20),               -- +34600000000
  
  -- Devolución
  return_type VARCHAR(20),                 -- 'cambio' | 'devolucion'
  items_json JSONB,                        -- [{...}]
  files_json JSONB,                        -- [{...}]
  razon TEXT,                              -- Razón
  
  -- Stripe
  amount NUMERIC(10,2),                    -- 150.00
  payment_status VARCHAR(20),              -- 'pending' | 'paid' | 'failed'
  stripe_session_id VARCHAR(150),          -- cs_live_xxxxx
  
  -- FedEx
  carrier VARCHAR(50),                     -- 'FEDEX' | 'UPS'
  tracking_number VARCHAR(50),             -- 7684294823
  label_base64 TEXT,                       -- PDF base64
  label_mime VARCHAR(50),                  -- 'application/pdf'
  label_created_at TIMESTAMP,              -- Fecha generación
  
  -- Workflow
  estado VARCHAR(20) DEFAULT 'pendiente',  -- 'pendiente' | 'aprobado' | 'rechazado'
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para queries rápidas
CREATE INDEX idx_return_requests_estado ON return_requests(estado);
CREATE INDEX idx_return_requests_request_id ON return_requests(request_id);
CREATE INDEX idx_return_requests_payment_status ON return_requests(payment_status);
```

### **Tabla: return_request_historial**

```sql
CREATE TABLE return_request_historial (
  id SERIAL PRIMARY KEY,
  request_id INTEGER NOT NULL REFERENCES return_requests(id) ON DELETE CASCADE,
  accion VARCHAR(50) NOT NULL,              -- 'pago_recibido' | 'aprobado' | 'rechazado'
  usuario VARCHAR(50) NOT NULL,             -- 'sistema' | 'admin'
  nota TEXT,                                -- Descripción
  metadata JSONB,                           -- Datos adicionales
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Auditoria
);

CREATE INDEX idx_historial_request_id ON return_request_historial(request_id);
CREATE INDEX idx_historial_fecha ON return_request_historial(fecha DESC);
```

---

## 🔐 Seguridad - Capas

### **Capa 1: API Key (Webhook)**
```python
if request.headers.get('X-API-KEY') != app.config['WEBHOOK_API_KEY']:
    return {'error': 'Unauthorized'}, 403
```
- Solo CYDMONBLEU puede enviar webhooks
- No requiere login del usuario

### **Capa 2: Autenticación (Dashboard/API)**
```python
@login_required
def dashboard():
    if 'usuario_id' not in session:
        return redirect(url_for('login'))
```
- Admin/Soporte deben login con usuario/contraseña
- Session cifrada con SECRET_KEY

### **Capa 3: Autorización (Roles)**
```python
@rol_required('admin', 'soporte')
def aprobar_solicitud(id):
    # Solo admin/soporte pueden aprobar
```
- Diferentes roles con diferentes permisos

### **Capa 4: HTTPS (Transporte)**
```
https://gestor-app.onrender.com/webhook/return-requests
```
- En producción, solo HTTPS
- Certificado SSL/TLS automático en Render

---

## 📊 Flujo de Estados

```
Solicitud creada (por webhook)
         ↓
    PENDIENTE ← Admin revisa
         ↓
    ┌────────────┬─────────────┐
    ↓            ↓             ↓
 APROBADA    RECHAZADA    EN_PROCESO (opcional)
    │            │             │
    └────────────┴─────────────┘
         ↓
    FINALIZADA (opcional)

Estados en BD:
  - pendiente (inicial)
  - aprobado (admin aprobó)
  - rechazado (admin rechazó)

Acciones historial:
  - pago_recibido (webhook)
  - guia_generada (si tracking_number)
  - aprobado (admin)
  - rechazado (admin)
  - notificacion_enviada (opcional)
```

---

## 🚀 Despliegue - Infraestructura

```
┌──────────────────────────────────────────────────────┐
│              GitHub (Repositorios)                   │
│  - CYDMONBLEU (Node.js)                             │
│  - GESTORCYDMONBLEU (Python/Flask)                  │
└──────────────────────────────────────────────────────┘
         │                           │
         ↓                           ↓
    ┌─────────────┐         ┌─────────────────┐
    │ Render      │         │ Render          │
    │ Node.js     │         │ Python          │
    │ App         │         │ App             │
    │ PORT 3000   │         │ PORT 5000       │
    └─────────────┘         └─────────────────┘
         │                           │
         └─────────────┬─────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ↓                             ↓
    ┌─────────────┐           ┌──────────────────┐
    │ Stripe API  │           │ PostgreSQL Neon  │
    │ (Pagos)     │           │ (Base de datos)  │
    │             │           │                  │
    └─────────────┘           └──────────────────┘
                                      │
                              ┌───────┴────────┐
                              ↓                ↓
                        Tablas:    Backups:
                        - return   - Daily
                        - historial- Weekly
                              ↓
                        ┌──────────────┐
                        │ Cloudflare   │
                        │ CDN/Cache    │
                        │ (opcional)   │
                        └──────────────┘
```

---

## 📈 Monitoreo y Alertas

### **Logs a Revisar:**
1. **GESTORCYDMONBLEU Logs:**
   ```
   - POST /webhook/return-requests
   - Database operations
   - Errors and exceptions
   ```

2. **CYDMONBLEU Logs:**
   ```
   - Fetch requests to webhook URL
   - Stripe webhook handling
   - FedEx API calls
   ```

3. **PostgreSQL Logs:**
   ```
   - Connection errors
   - Query performance
   - Disk space
   ```

### **Métricas a Monitorear:**
- Webhook success rate (% 201 responses)
- Average webhook response time
- Database query performance
- Error rate (4xx, 5xx responses)
- Solicitudes por estado (pending/approved/rejected)

### **Alertas Recomendadas:**
- Webhook falla 3 veces consecutivas
- Tiempo de respuesta > 5 segundos
- Error rate > 5%
- Espacio en BD < 10%

---

## ✅ INTEGRACIÓN LISTA

**Estado:** ✅ 100% Compatible y documentada

**Verificar:**
1. ✅ Modelos de datos coinciden
2. ✅ Endpoints implementados
3. ✅ Seguridad configurada
4. ✅ Base de datos diseñada
5. ✅ Flujo de estados definido
6. ✅ Variables de entorno especificadas
7. ✅ Documentación completa

**Próximo paso:** Desplegar en Render y probar con webhook real
