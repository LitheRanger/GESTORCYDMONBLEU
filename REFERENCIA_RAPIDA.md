# ⚡ REFERENCIA RÁPIDA - INTEGRACIÓN

## 🎯 Respuesta a tu pregunta: ¿Funcionarían juntos?

### ✅ SÍ, 100% COMPATIBLE

---

## 🔗 Cómo Funciona la Integración

```
┌─ CYDMONBLEU (Node.js) ─┐         ┌─ GESTORCYDMONBLEU (Python) ─┐
│ 1. Cliente solicita    │         │ 5. Recibe webhook            │
│ 2. Cliente paga        │ POST    │ 6. Crea en BD                │
│ 3. FedEx genera label  ├────────→│ 7. Muestra en Kanban         │
│ 4. Envía webhook       │ JSON    │ 8. Admin aprueba/rechaza     │
│                        │ + KEY   │ 9. Registra historial        │
└────────────────────────┘         └──────────────────────────────┘
```

---

## 🔑 Configuración Mínima Necesaria

### En `CYDMONBLEU/.env`
```env
GESTOR_WEBHOOK_URL=http://localhost:5000/webhook/return-requests
WEBHOOK_API_KEY=webhook-demo-key
```

### En `GESTORCYDMONBLEU/.env`
```env
DATABASE_URL=postgresql://user:pass@host/db
WEBHOOK_API_KEY=webhook-demo-key
SECRET_KEY=tu-clave-segura
```

**⚠️ IMPORTANTE:** `WEBHOOK_API_KEY` debe ser IDÉNTICA en ambos

---

## ✅ Lo Que Ya Está Listo

| Componente | Estado |
|-----------|--------|
| app.py (actualizado) | ✅ |
| Modelo ReturnRequest | ✅ |
| Webhook endpoint | ✅ |
| Dashboard Kanban | ✅ |
| Templates | ✅ |
| Migración SQL | ✅ |
| Seguridad | ✅ |
| API endpoints | ✅ |

---

## 🚀 Para Activar (5 pasos)

1. **Configura `.env` en ambas carpetas**
   - Misma `WEBHOOK_API_KEY`
   - URL correcta del webhook

2. **Crea tablas en GESTORCYDMONBLEU**
   ```bash
   python app.py
   # Luego acceder a: /init-db
   ```

3. **Crea usuarios**
   - Acceder a: `/crear-usuarios`
   - O insertar manualmente

4. **Prueba webhook**
   ```bash
   curl -X POST http://localhost:5000/webhook/return-requests \
     -H "X-API-KEY: webhook-demo-key" \
     -H "Content-Type: application/json" \
     -d '{"request_id":"REQ-TEST","order_id":"#1","cliente":{"nombre":"Test","email":"test@test.com"},"tipo":"devolucion","items":[],"razon":"Test","amount":150,"payment_status":"paid"}'
   ```

5. **Desplega en Render**
   - Push a GitHub
   - Conecta repos en Render
   - Configura variables de entorno
   - ¡Listo!

---

## 📊 Flujo Completo

```
CLIENTE               CYDMONBLEU              WEBHOOK             GESTORCYDMONBLEU
────────              ─────────               ─────               ─────────────────
  │                     │
  ├─ Completa form ────→ │
  │                     │
  ├─ Sube fotos ───────→ │
  │                     │
  ├─ Paga Stripe ──────→ │
  │                     │
  ├─ FedEx label ──────→ │
  │                     │
  │           Webhook POST ────────────────────→ Recibe
  │                     │                        │
  │                     │                        ├─ Valida X-API-KEY ✓
  │                     │                        ├─ Crea solicitud
  │                     │                        ├─ Registra historial
  │                     │                        └─ Responde 201 ✓
  │                     │
  │                     │        API GET ←──── Consulta estado (opcional)
  │                     │                    
  │                 [DASHBOARD KANBAN]
  │                 [ADMIN VE SOLICITUD]
  │                 [ADMIN APRUEBA]
  │                     │
  │           API Response ←──── Estado: "aprobado"
  │
  └─ Recibe confirmación
```

---

## 🧪 Tests Rápidos

### Test 1: ¿Webhook funciona?
```bash
curl -X POST http://localhost:5000/webhook/return-requests \
  -H "X-API-KEY: webhook-demo-key" \
  -H "Content-Type: application/json" \
  -d '{"request_id":"TEST-001","order_id":"#001","cliente":{"nombre":"Test","email":"t@t.com"},"tipo":"devolucion","items":[],"razon":"Test","amount":150,"payment_status":"paid"}'

# Debe retornar: {"status": "ok", "request_id": "TEST-001", "id": 1}
```

### Test 2: ¿Aparece en dashboard?
```
http://localhost:5000/login
Usuario: admin
Contraseña: 1234
```

### Test 3: ¿API funciona?
```bash
curl -X GET "http://localhost:5000/api/return-requests" \
  -H "Authorization: Basic admin:1234"

# Debe retornar: {"success": true, "total": 1, "data": [...]}
```

---

## ⚠️ Errores Comunes

| Error | Causa | Solución |
|-------|-------|----------|
| 403 Unauthorized | X-API-KEY no coincide | Revisar .env |
| 400 Bad Request | JSON malformado | Validar estructura |
| 500 Server Error | BD no existe | Ejecutar /init-db |
| Webhook no se dispara | URL incorrecta | Revisar GESTOR_WEBHOOK_URL |
| Admin no puede aprobar | Usuario no existe | Ejecutar /crear-usuarios |

---

## 📈 Monitoreo

Revisar:
- Logs de Flask (errores del webhook)
- Tabla `return_requests` (solicitudes creadas)
- Tabla `return_request_historial` (auditoría)

---

## 💡 Pro Tips

✅ Usa variables de entorno para URLs (facilita desarrollo/producción)
✅ Prueba localmente antes de desplegar
✅ Mantén logs activos en producción
✅ Configura alertas si webhook falla
✅ Backup regular de PostgreSQL

---

## 📚 Documentación Completa

Hay 6 documentos con detalles completos:
1. **RESUMEN_EJECUTIVO.md** - Resumen general
2. **ANALISIS_COMPATIBILIDAD.md** - Análisis técnico
3. **ARQUITECTURA_INTEGRACION.md** - Diagramas y detalles
4. **CHECKLIST_INTEGRACION.md** - Pasos verificables
5. **IMPLEMENTACION_COMPLETADA.md** - Guía de instalación
6. **CAMBIOS_COMPLETADOS.md** - Resumen de cambios

---

## ✅ CONCLUSIÓN

**Las aplicaciones funcionan perfectamente juntas**

Basta con:
1. Configurar variables de entorno
2. Ejecutar migraciones SQL
3. Crear usuarios
4. Probar webhook
5. Desplegar

¡Listo para producción! 🚀

---

**Versión:** Referencia Rápida v1.0  
**Fecha:** 31/01/2026
