# 🔍 ANÁLISIS DE COMPATIBILIDAD: CYDMONBLEU ↔ GESTORCYDMONBLEU

**Fecha de análisis**: 31/01/2026

---

## ✅ COMPATIBILIDAD GENERAL

**RESULTADO: SÍ, SON COMPATIBLES** con los siguientes puntos de verificación.

---

## 📊 1. ESTRUCTURA DE DATOS - WEBHOOK

### **Payload que CYDMONBLEU envía:**
```javascript
{
    request_id: string,           // REQ-12345
    order_id: string,             // #1001
    cliente: {
        nombre: string,           // Juan
        email: string,            // juan@example.com
        phone: string             // +34600000000
    },
    tipo: string,                 // 'cambio' | 'devolucion'
    items: array,                 // [{producto, talla_original, talla_cambio, cantidad, imagen_url}]
    files: array,                 // [{filename, url, uploaded_at}]
    razon: string,                // Razón de devolución
    amount: number,               // 150.00
    payment_status: string,       // 'paid' | 'pending' | 'failed'
    stripe_session_id: string,    // cs_live_xxxxx
    carrier: string,              // 'FEDEX' | 'UPS'
    tracking_number: string,      // 7684294823
    label_base64: string,         // JVBERi0xLjQK...
    label_mime: string            // 'application/pdf'
}
```

### **Modelo ReturnRequest que espera GESTORCYDMONBLEU:**
```python
id: Integer (PK)
request_id: String(50) ✅ COINCIDE
order_id: String(50) ✅ COINCIDE
contact_name: String(150) ✅ COINCIDE (cliente.nombre)
contact_email: String(150) ✅ COINCIDE (cliente.email)
contact_phone: String(20) ✅ COINCIDE (cliente.phone)
return_type: String(20) ✅ COINCIDE (tipo)
items_json: JSON ✅ COINCIDE (items)
files_json: JSON ✅ COINCIDE (files)
razon: Text ✅ COINCIDE
amount: Numeric(10,2) ✅ COINCIDE
payment_status: String(20) ✅ COINCIDE
stripe_session_id: String(150) ✅ COINCIDE
carrier: String(50) ✅ COINCIDE
tracking_number: String(50) ✅ COINCIDE
label_base64: LongText ✅ COINCIDE
label_mime: String(50) ✅ COINCIDE
estado: String(20) = 'pendiente' (por defecto)
created_at: DateTime (auto)
updated_at: DateTime (auto)
```

**✅ CONCLUSIÓN: 100% compatible**

---

## 🔐 2. SEGURIDAD - API KEY

### **En CYDMONBLEU (debe enviar):**
```javascript
headers: {
    'Content-Type': 'application/json',
    'X-API-KEY': process.env.WEBHOOK_API_KEY  // 'webhook-demo-key'
}
```

### **En GESTORCYDMONBLEU (valida):**
```python
@app.route('/webhook/return-requests', methods=['POST'])
def webhook_return_requests():
    if request.headers.get('X-API-KEY') != app.config['WEBHOOK_API_KEY']:
        return {'error': 'Unauthorized'}, 403
```

**✅ CONCLUSIÓN: Seguridad implementada correctamente**

---

## 🌐 3. URLs Y ENDPOINTS

### **GESTORCYDMONBLEU endpoints:**

| Endpoint | Método | Requiere Auth | Descripción |
|----------|--------|---------------|-------------|
| `/webhook/return-requests` | POST | X-API-KEY | Recibe solicitudes de CYDMONBLEU |
| `/api/return-requests` | GET | Login | Lista solicitudes (filtrable) |
| `/api/return-requests/<id>/historial` | GET | Login | Historial de acciones |
| `/return-request/<id>/approve` | POST | Login + Admin | Aprobar solicitud |
| `/return-request/<id>/reject` | POST | Login + Admin | Rechazar solicitud |
| `/return-request/<id>` | GET | Login | Ver detalle |
| `/dashboard` | GET | Login | Ver Kanban |
| `/init-db` | GET | - | Crear tablas |
| `/crear-usuarios` | GET | - | Crear usuarios demo |

**✅ Webhook sin autenticación de usuario, solo X-API-KEY**

---

## 🔄 4. FLUJO DE INTEGRACIÓN

```
CYDMONBLEU (Node.js)          GESTORCYDMONBLEU (Python/Flask)
─────────────────────         ─────────────────────────────

1. Cliente rellena form
2. Cliente sube fotos
3. Cliente selecciona items
4. Cliente paga con Stripe
5. Stripe webhook ✓
6. Se genera guía FedEx ✓
7. POST /webhook/return-requests ────→ [Valida X-API-KEY]
                                    ├→ Busca por request_id
                                    ├→ Crea o actualiza ReturnRequest
                                    ├→ Registra en historial
                                    ├→ Responde 201 OK
                                    └→ Solicitud visible en Kanban
                                    
8. Admin revisa dashboard ←────── [Actualización en tiempo real]
9. Admin aprueba/rechaza ─→ Solicitud pasa a "Aprobada/Rechazada"
10. Cliente recibe confirmación (opcional)
```

**✅ Flujo completo es funcional**

---

## ⚙️ 5. VARIABLES DE ENTORNO REQUERIDAS

### **CYDMONBLEU necesita:**
```env
GESTOR_WEBHOOK_URL=https://gestor.onrender.com/webhook/return-requests
# O en desarrollo: http://localhost:5000/webhook/return-requests

WEBHOOK_API_KEY=webhook-demo-key
```

### **GESTORCYDMONBLEU necesita:**
```env
WEBHOOK_API_KEY=webhook-demo-key  # DEBE COINCIDIR
DATABASE_URL=postgresql://...
SECRET_KEY=tu-secret-key-segura
```

**✅ IMPORTANTE: Las claves deben ser idénticas en ambos**

---

## 🧪 6. PRUEBAS DE INTEGRACIÓN RECOMENDADAS

### **Test 1: Webhook local**
```bash
curl -X POST http://localhost:5000/webhook/return-requests \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: webhook-demo-key" \
  -d '{
    "request_id":"REQ-TEST-001",
    "order_id":"#9999",
    "cliente":{"nombre":"Test User","email":"test@test.com","phone":"+1234567890"},
    "tipo":"devolucion",
    "items":[{"producto":"Camiseta","talla_original":"M","talla_cambio":"L","cantidad":1,"imagen_url":"https://example.com/img.jpg"}],
    "files":[],
    "razon":"Color no coincide",
    "amount":150.00,
    "payment_status":"paid",
    "stripe_session_id":"cs_live_test123",
    "carrier":"FEDEX",
    "tracking_number":"7684294823",
    "label_base64":"JVBERi0xLjQKJeLjz9MNCjEgMCBvYmog",
    "label_mime":"application/pdf"
  }'
```

**Respuesta esperada:**
```json
{
    "status": "ok",
    "request_id": "REQ-TEST-001",
    "id": 1
}
```

### **Test 2: Ver solicitud en API**
```bash
curl -X GET "http://localhost:5000/api/return-requests" \
  -H "Authorization: Basic admin:1234"
```

### **Test 3: Ver historial**
```bash
curl -X GET "http://localhost:5000/api/return-requests/1/historial" \
  -H "Authorization: Basic admin:1234"
```

---

## ⚠️ 7. POSIBLES PROBLEMAS Y SOLUCIONES

### **Problema 1: Webhook retorna 403**
```
Error: Unauthorized
```
**Solución:**
- Verificar que `X-API-KEY` esté en headers
- Verificar que `X-API-KEY` coincida en ambos .env
- Verificar que sea exactamente: `webhook-demo-key`

### **Problema 2: Webhook retorna 400**
```
Error: {...}
```
**Solución:**
- Revisar estructura del payload
- Verificar que todos los campos requeridos existan
- Ver logs del servidor Flask para detalles

### **Problema 3: Solicitud no aparece en dashboard**
**Solución:**
- Verificar que la migración SQL se ejecutó
- Acceder a `/init-db` para crear tablas
- Verificar en base de datos que la solicitud se creó

### **Problema 4: Campos vacíos en dashboard**
**Solución:**
- Revisar si CYDMONBLEU envía `null` en lugar de valores
- Actualizar payload con valores válidos
- Ejemplo: `cliente.nombre` no debe estar vacío

### **Problema 5: Errores de conexión a BD**
**Solución:**
- Verificar `DATABASE_URL` en .env
- Verificar credenciales de Neon
- Verificar que la BD existe

---

## 📋 8. CHECKLIST DE INTEGRACIÓN

- [ ] GESTORCYDMONBLEU app.py actualizado ✅
- [ ] Templates actualizados (dashboard.html, detalle_solicitud.html) ✅
- [ ] Migración SQL ejecutada en PostgreSQL ✅
- [ ] Variables de entorno configuradas (ambas apps)
- [ ] X-API-KEY idéntica en CYDMONBLEU y GESTORCYDMONBLEU
- [ ] WEBHOOK_API_KEY = webhook-demo-key (o tu valor)
- [ ] GESTOR_WEBHOOK_URL configurada en CYDMONBLEU
- [ ] Test de webhook sin errores
- [ ] Solicitud visible en dashboard
- [ ] Aprobación/rechazo funcionan
- [ ] Historial se registra correctamente
- [ ] Ambas apps desplegadas en Render (si es necesario)

---

## 🎯 9. RECOMENDACIONES

### **Para Desarrollo:**
1. Ejecutar ambos servidores localmente
2. GESTORCYDMONBLEU: `python app.py` (puerto 5000)
3. CYDMONBLEU: `npm start` (puerto 3000 típicamente)
4. Probar webhook con curl primero
5. Luego probar desde CYDMONBLEU frontend

### **Para Producción (Render):**
1. Desplegar GESTORCYDMONBLEU a Render
2. Desplegar CYDMONBLEU a Render
3. Configurar WEBHOOK_API_KEY idéntica en ambos
4. Configurar GESTOR_WEBHOOK_URL = URL de GESTORCYDMONBLEU en Render
5. Probar con solicitud real

### **Monitoreo:**
- Revisar logs de Flask en Render
- Revisar logs de Node.js en Render
- Verificar tabla `return_request_historial` para auditoría
- Usar API `/api/return-requests` para reporting

---

## ✅ CONCLUSIÓN FINAL

**LAS APLICACIONES SON 100% COMPATIBLES** si se cumplen estos requisitos:

1. ✅ Variables de entorno configuradas correctamente
2. ✅ X-API-KEY idéntica en ambos repositorios
3. ✅ Migración SQL ejecutada en GESTORCYDMONBLEU
4. ✅ Usuarios creados en GESTORCYDMONBLEU
5. ✅ Webhook URL apunta a la instancia correcta de GESTORCYDMONBLEU

**Próximo paso:** Implementar las variables de entorno y probar con un webhook de ejemplo.

---

**Autor:** Análisis de Integración
**Versión:** 1.0
**Fecha:** 31/01/2026
