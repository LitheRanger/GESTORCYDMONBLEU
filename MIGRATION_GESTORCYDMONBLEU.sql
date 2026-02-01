-- MIGRATION_GESTORCYDMONBLEU.sql
-- Script de migración para actualizar base de datos
-- Compatibilidad con integración Stripe + FedEx

-- ======================================
-- 1. Crear tabla de usuarios (si no existe)
-- ======================================
CREATE TABLE IF NOT EXISTS usuario (
    id SERIAL PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_usuario_usuario ON usuario(usuario);

-- ======================================
-- 2. Crear tabla de solicitudes mejorada
-- ======================================
CREATE TABLE IF NOT EXISTS return_requests (
    id SERIAL PRIMARY KEY,
    
    -- Identificadores
    request_id VARCHAR(50) UNIQUE NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    
    -- Cliente
    contact_name VARCHAR(150),
    contact_email VARCHAR(150),
    contact_phone VARCHAR(20),
    
    -- Devolución
    return_type VARCHAR(20),  -- cambio, devolucion
    items_json JSONB,  -- [{ producto, talla_original, talla_cambio, cantidad, imagen_url }]
    files_json JSONB,  -- [{ filename, url, uploaded_at }]
    razon TEXT,  -- Razón de devolución
    
    -- Pago (Stripe)
    amount NUMERIC(10, 2) DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'pending',  -- pending, paid, failed
    stripe_session_id VARCHAR(150),
    
    -- Envío (FedEx)
    carrier VARCHAR(50),  -- FEDEX, UPS, etc.
    tracking_number VARCHAR(50),
    label_base64 TEXT,  -- PDF en base64
    label_mime VARCHAR(50),  -- application/pdf
    label_created_at TIMESTAMP,
    
    -- Workflow
    estado VARCHAR(20) DEFAULT 'pendiente',  -- pendiente, aprobado, rechazado
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices para queries frecuentes
CREATE INDEX IF NOT EXISTS idx_return_requests_estado ON return_requests(estado);
CREATE INDEX IF NOT EXISTS idx_return_requests_order_id ON return_requests(order_id);
CREATE INDEX IF NOT EXISTS idx_return_requests_payment_status ON return_requests(payment_status);
CREATE INDEX IF NOT EXISTS idx_return_requests_created_at ON return_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_return_requests_request_id ON return_requests(request_id);

-- ======================================
-- 3. Crear tabla de historial
-- ======================================
CREATE TABLE IF NOT EXISTS return_request_historial (
    id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES return_requests(id) ON DELETE CASCADE,
    accion VARCHAR(50) NOT NULL,  -- aprobado, rechazado, pago_recibido, guia_generada
    usuario VARCHAR(50) NOT NULL,
    nota TEXT,
    metadata JSONB,  -- datos adicionales
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_historial_request_id ON return_request_historial(request_id);
CREATE INDEX IF NOT EXISTS idx_historial_fecha ON return_request_historial(fecha DESC);
CREATE INDEX IF NOT EXISTS idx_historial_accion ON return_request_historial(accion);

-- ======================================
-- 4. Insertar usuarios de demo (si no existen)
-- ======================================
INSERT INTO usuario (usuario, password_hash, rol) VALUES
('admin', 'pbkdf2:sha256:600000$0a1b2c3d4e5f6g7h$' || 'f' || (SELECT COUNT(*) FROM usuario), 'admin')
ON CONFLICT (usuario) DO NOTHING;

-- Para soporte, generar hash: werkzeug.security.generate_password_hash('1234')
-- Admin hash para '1234': pbkdf2:sha256:600000$XXXX$XXXX (depende del salt)
-- Es mejor usar /crear-usuarios desde la web

-- ======================================
-- 5. Vistas útiles (opcional)
-- ======================================

-- Vista: Resumen de solicitudes por estado
CREATE OR REPLACE VIEW v_return_requests_summary AS
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) as pendientes,
    SUM(CASE WHEN estado = 'aprobado' THEN 1 ELSE 0 END) as aprobadas,
    SUM(CASE WHEN estado = 'rechazado' THEN 1 ELSE 0 END) as rechazadas,
    SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) as pagadas,
    SUM(CASE WHEN payment_status = 'pending' THEN 1 ELSE 0 END) as pagos_pendientes,
    SUM(CASE WHEN tracking_number IS NOT NULL THEN 1 ELSE 0 END) as con_guia
FROM return_requests;

-- Vista: Solicitudes con historial reciente
CREATE OR REPLACE VIEW v_return_requests_with_latest_action AS
SELECT 
    r.id,
    r.request_id,
    r.order_id,
    r.contact_name,
    r.contact_email,
    r.amount,
    r.payment_status,
    r.estado,
    r.created_at,
    (SELECT accion FROM return_request_historial WHERE request_id = r.id ORDER BY fecha DESC LIMIT 1) as ultima_accion,
    (SELECT fecha FROM return_request_historial WHERE request_id = r.id ORDER BY fecha DESC LIMIT 1) as fecha_ultima_accion
FROM return_requests r;

-- ======================================
-- 6. Comentarios y documentación
-- ======================================
COMMENT ON TABLE return_requests IS 'Solicitudes de cambio/devolución con integración Stripe + FedEx';
COMMENT ON COLUMN return_requests.request_id IS 'ID único de solicitud generado por CYDMONBLEU (ej: REQ-12345)';
COMMENT ON COLUMN return_requests.stripe_session_id IS 'Session ID del checkout de Stripe para verificar pagos';
COMMENT ON COLUMN return_requests.tracking_number IS 'Número de tracking del envío FedEx';
COMMENT ON COLUMN return_requests.label_base64 IS 'Etiqueta FedEx codificada en base64';

COMMENT ON TABLE return_request_historial IS 'Registro de todas las acciones realizadas en cada solicitud';
COMMENT ON COLUMN return_request_historial.metadata IS 'JSON con datos adicionales según la acción (tracking, monto, etc)';

-- ======================================
-- 7. Triggers (opcional, para auditoria)
-- ======================================

-- Trigger: Actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_return_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_return_requests_updated_at ON return_requests;
CREATE TRIGGER trigger_update_return_requests_updated_at
BEFORE UPDATE ON return_requests
FOR EACH ROW
EXECUTE FUNCTION update_return_requests_updated_at();

-- ======================================
-- Fin de la migración
-- ======================================
-- Ejecutar: psql -d neondb -U neondb_owner -h host -f MIGRATION_GESTORCYDMONBLEU.sql
-- O desde Python: from app import db; db.create_all()
