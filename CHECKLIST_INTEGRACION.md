# ✔️ CHECKLIST PRE-INTEGRACIÓN

## 🚀 Antes de conectar CYDMONBLEU con GESTORCYDMONBLEU

---

## 1️⃣ GESTORCYDMONBLEU - Configuración Local

### Base de Datos
- [ ] PostgreSQL/Neon está funcionando
- [ ] Ejecutar: `from app import db, app; app.app_context().push(); db.create_all()`
- [ ] O acceder a: `http://localhost:5000/init-db`
- [ ] Verificar tablas creadas:
  - [ ] `usuario` (existe)
  - [ ] `return_requests` (existe)
  - [ ] `return_request_historial` (existe)

### Usuarios
- [ ] Ejecutar: `http://localhost:5000/crear-usuarios`
- [ ] O insertar manualmente en BD:
  ```sql
  INSERT INTO usuario (usuario, password_hash, rol) VALUES
  ('admin', 'pbkdf2:sha256:...', 'admin'),
  ('soporte', 'pbkdf2:sha256:...', 'soporte');
  ```
- [ ] Verificar credenciales: admin/1234, soporte/1234

### Variables de Entorno
- [ ] Crear `.env` en raíz de GESTORCYDMONBLEU:
  ```env
  SECRET_KEY=dev-secret-key-cambiar-en-produccion
  DATABASE_URL=postgresql://usuario:contraseña@host:5432/neondb
  WEBHOOK_API_KEY=webhook-demo-key
  FLASK_ENV=development
  ```
- [ ] Revisar que `WEBHOOK_API_KEY=webhook-demo-key`

### Pruebas Locales
- [ ] Ejecutar `python app.py`
- [ ] Acceder a `http://localhost:5000/login`
- [ ] Login con admin/1234
- [ ] Ver dashboard vacío (sin solicitudes aún)

---

## 2️⃣ Webhook Local - Test básico

### Prueba sin autenticación (debe funcionar)
```bash
curl -X POST http://localhost:5000/webhook/return-requests \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: webhook-demo-key" \
  -d '{"request_id":"REQ-LOCAL-TEST","order_id":"#0001","cliente":{"nombre":"Test","email":"test@test.com"},"tipo":"devolucion","items":[],"files":[],"razon":"Test","amount":150,"payment_status":"paid","stripe_session_id":"test123","carrier":"FEDEX","tracking_number":"123456789","label_base64":"","label_mime":"application/pdf"}'
```

**Respuestas esperadas:**
- [ ] 201 Created (éxito)
- [ ] JSON: `{"status": "ok", "request_id": "REQ-LOCAL-TEST", "id": 1}`

### Si falla:
- [ ] ❌ 403 Unauthorized → Revisar X-API-KEY
- [ ] ❌ 400 Bad Request → Revisar estructura JSON
- [ ] ❌ Connection refused → Servidor no está corriendo

---

## 3️⃣ Dashboard - Verificación Visual

### Después de webhook exitoso:
- [ ] Acceder a `http://localhost:5000/`
- [ ] Debe aparecer solicitud en columna "Pendientes"
- [ ] Mostrar: request_id, cliente, razón, monto
- [ ] Botones: Aprobar, Rechazar, Ver detalle

### Hacer click en "Ver detalle":
- [ ] URL es: `http://localhost:5000/return-request/1`
- [ ] Mostrar toda la información
- [ ] Mostrar historial (debe haber 1 entrada: "pago_recibido")

### Aprobar solicitud:
- [ ] Hacer click en "Aprobar"
- [ ] Solicitud se mueve a columna "Aprobadas"
- [ ] Historial tiene nueva entrada: "aprobado"

---

## 4️⃣ CYDMONBLEU - Configuración

### Variables de Entorno (en CYDMONBLEU):
- [ ] Crear `.env` en raíz:
  ```env
  GESTOR_WEBHOOK_URL=http://localhost:5000/webhook/return-requests
  # Para Render: https://gestor-app.onrender.com/webhook/return-requests
  
  WEBHOOK_API_KEY=webhook-demo-key
  ```
- [ ] Revisar que coincida con GESTORCYDMONBLEU

### Código Node.js (server.js):
- [ ] Buscar función que envía webhook
- [ ] Verificar estructura del payload
- [ ] Verificar headers: `X-API-KEY` y `Content-Type`
- [ ] URL correcta: `process.env.GESTOR_WEBHOOK_URL`

### Ejemplo esperado en CYDMONBLEU:
```javascript
async function sendToGestor(requestData) {
  const url = process.env.GESTOR_WEBHOOK_URL || 'http://localhost:5000/webhook/return-requests';
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': process.env.WEBHOOK_API_KEY
      },
      body: JSON.stringify({
        request_id: requestData.request_id,
        order_id: requestData.order_id,
        cliente: {
          nombre: requestData.contact_email.split('@')[0],
          email: requestData.contact_email,
          phone: requestData.contact_phone || ''
        },
        tipo: requestData.return_type,
        items: requestData.items || [],
        files: requestData.files || [],
        razon: requestData.razon,
        amount: requestData.amount,
        payment_status: 'paid',
        stripe_session_id: requestData.stripe_session_id,
        carrier: requestData.carrier || 'FEDEX',
        tracking_number: requestData.tracking_number,
        label_base64: requestData.label_base64,
        label_mime: requestData.label_mime || 'application/pdf'
      })
    });
    
    if (!response.ok) {
      console.error('Webhook error:', response.status, await response.text());
    }
  } catch (err) {
    console.error('Webhook failed:', err);
  }
}
```

---

## 5️⃣ Test de Integración (Desarrollo Local)

### Escenario: Cliente completa solicitud en CYDMONBLEU

1. **En CYDMONBLEU:**
   - [ ] Cliente rellena formulario de devolución
   - [ ] Cliente sube fotos/evidencia
   - [ ] Cliente selecciona items
   - [ ] Cliente paga con Stripe ($150)
   - [ ] Sistema genera tracking FedEx
   - [ ] WEBHOOK se dispara → POST a GESTORCYDMONBLEU

2. **En GESTORCYDMONBLEU:**
   - [ ] Webhook recibido (status 201)
   - [ ] Solicitud creada en BD
   - [ ] Aparece en Kanban (columna Pendientes)
   - [ ] Historial registra: "pago_recibido"

3. **En Dashboard GESTORCYDMONBLEU:**
   - [ ] Admin ve solicitud nueva
   - [ ] Admin revisa detalles
   - [ ] Admin aprueba (botón "✅ Aprobar")
   - [ ] Solicitud se mueve a "Aprobadas"
   - [ ] Historial registra: "aprobado" + usuario

4. **De vuelta en CYDMONBLEU (opcional):**
   - [ ] Sistema consulta estado en GESTORCYDMONBLEU (GET /api/return-requests)
   - [ ] Actualiza UI del cliente con estado
   - [ ] Envía confirmación por email

---

## 6️⃣ API Endpoints - Verificación

### Listar solicitudes
```bash
curl -X GET "http://localhost:5000/api/return-requests" \
  -H "Authorization: Basic admin:1234"
```
- [ ] Retorna 200 OK
- [ ] JSON con array de solicitudes

### Filtrar por estado
```bash
curl -X GET "http://localhost:5000/api/return-requests?estado=pendiente" \
  -H "Authorization: Basic admin:1234"
```
- [ ] Retorna solo solicitudes pendientes

### Ver historial
```bash
curl -X GET "http://localhost:5000/api/return-requests/1/historial" \
  -H "Authorization: Basic admin:1234"
```
- [ ] Retorna array con acciones

---

## 7️⃣ Despliegue en Render

### GESTORCYDMONBLEU:
- [ ] Código actualizado en GitHub
- [ ] `.env` configurado en Render (no en repo)
- [ ] Variable: `WEBHOOK_API_KEY=webhook-demo-key`
- [ ] Variable: `DATABASE_URL=...neon...`
- [ ] Variable: `SECRET_KEY=...seguro...`
- [ ] Desploy ejecutado exitosamente
- [ ] URL: https://gestor-app.onrender.com (ejemplo)

### CYDMONBLEU:
- [ ] `.env` configurado en Render
- [ ] Variable: `GESTOR_WEBHOOK_URL=https://gestor-app.onrender.com/webhook/return-requests`
- [ ] Variable: `WEBHOOK_API_KEY=webhook-demo-key` (coincide)
- [ ] Desploy ejecutado exitosamente
- [ ] URL: https://cydmonbleu.onrender.com (ejemplo)

---

## 8️⃣ Seguridad - Verificaciones Finales

- [ ] `X-API-KEY` no está en código, solo en `.env`
- [ ] URLs de webhook usan HTTPS en producción
- [ ] Base de datos está en Neon (no local)
- [ ] Credenciales no están en repositorio
- [ ] `.env` está en `.gitignore`
- [ ] WEBHOOK_API_KEY es segura (cambiar de `webhook-demo-key`)
- [ ] SECRET_KEY es segura en producción

---

## 9️⃣ Monitoreo - Post-Integración

### Logs para revisar:
- [ ] GESTORCYDMONBLEU: Ver logs de Flask en Render
- [ ] CYDMONBLEU: Ver logs de Node.js en Render
- [ ] Buscar: "Webhook" en logs
- [ ] Buscar: "error" en logs

### Base de datos:
- [ ] Verificar tabla `return_requests` tiene datos
- [ ] Verificar tabla `return_request_historial` tiene registros
- [ ] Ejecutar: `SELECT * FROM v_return_requests_summary;`

### Alertas a configurar:
- [ ] Webhook falla (400, 403, 500)
- [ ] Solicitud no se crea
- [ ] Historial no se registra

---

## 🔟 Problemas Comunes - Soluciones Rápidas

| Problema | Causa | Solución |
|----------|-------|----------|
| Webhook 403 | X-API-KEY no coincide | Revisar .env en ambas apps |
| Webhook 400 | JSON malformado | Validar estructura del payload |
| Solicitud no aparece | BD no se creó | Ejecutar /init-db |
| Dashboard vacío | Webhook no se dispara | Revisar logs de CYDMONBLEU |
| Historial no registra | Error en base de datos | Verificar migración SQL |
| Usuarios no existen | No ejecutado /crear-usuarios | Acceder a /crear-usuarios |
| Error de conexión | URL incorrecta | Revisar GESTOR_WEBHOOK_URL |

---

## ✅ INTEGRACIÓN COMPLETADA

Cuando todos los checkboxes estén marcados, la integración está lista:

```
CYDMONBLEU (Formulario + Pago + FedEx)
        ↓ WEBHOOK
GESTORCYDMONBLEU (Kanban + Aprobación + Historial)
```

**Estado**: ✅ **100% Compatible y listo para integrar**

---

**Próximo paso:** Configurar variables de entorno y desplegar en Render
