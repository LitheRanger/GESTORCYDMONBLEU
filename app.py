from flask import Flask, render_template, request, redirect, url_for, flash, session, abort
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from datetime import datetime
import os

# ================== CONFIG ==================
app = Flask(__name__)

app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')

app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'DATABASE_URL',
    'postgresql://USUARIO:PASSWORD@HOST/neondb?sslmode=require'
)

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Clave simple para proteger el webhook
app.config['WEBHOOK_API_KEY'] = os.environ.get('WEBHOOK_API_KEY', 'webhook-demo-key')

db = SQLAlchemy(app)

# ================== DECORADORES ==================
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'usuario_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated


def rol_required(*roles):
    def decorator(f):
        @wraps(f)
        def wrapped(*args, **kwargs):
            if session.get('rol') not in roles:
                flash('Acceso no autorizado', 'danger')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return wrapped
    return decorator


# ================== MODELOS ==================
class Usuario(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    usuario = db.Column(db.String(50), unique=True)
    password_hash = db.Column(db.String(255))
    rol = db.Column(db.String(20))

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)


class Solicitud(db.Model):
    id = db.Column(db.Integer, primary_key=True)

    request_id = db.Column(db.String(50), unique=True)
    tipo = db.Column(db.String(20))              # cambio | devolucion
    estado = db.Column(db.String(20), default='pendiente')

    cliente_nombre = db.Column(db.String(150))
    cliente_email = db.Column(db.String(150))
    pedido_id = db.Column(db.String(50))

    razon = db.Column(db.Text)

    raw_data = db.Column(db.JSON)                # payload completo del webhook

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )


class SolicitudHistorial(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    solicitud_id = db.Column(db.Integer, db.ForeignKey('solicitud.id'))
    accion = db.Column(db.String(50))             # aprobado | rechazado
    usuario = db.Column(db.String(50))
    nota = db.Column(db.Text)
    fecha = db.Column(db.DateTime, default=datetime.utcnow)


# ================== LOGIN ==================
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        u = Usuario.query.filter_by(usuario=request.form['usuario']).first()
        if u and u.check_password(request.form['password']):
            session['usuario_id'] = u.id
            session['usuario'] = u.usuario
            session['rol'] = u.rol
            return redirect(url_for('dashboard'))
        flash('Credenciales incorrectas', 'danger')
    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


# ================== DASHBOARD ==================
@app.route('/')
@login_required
def dashboard():
    pendientes = Solicitud.query.filter_by(estado='pendiente').order_by(Solicitud.created_at.desc()).all()
    aprobadas = Solicitud.query.filter_by(estado='aprobado').order_by(Solicitud.created_at.desc()).all()
    rechazadas = Solicitud.query.filter_by(estado='rechazado').order_by(Solicitud.created_at.desc()).all()

    return render_template(
        'dashboard.html',
        pendientes=pendientes,
        aprobadas=aprobadas,
        rechazadas=rechazadas
    )


# ================== ACCIONES ==================
@app.route('/solicitud/<int:id>/aprobar', methods=['POST'])
@login_required
@rol_required('admin', 'soporte')
def aprobar_solicitud(id):
    s = Solicitud.query.get_or_404(id)
    s.estado = 'aprobado'

    db.session.add(
        SolicitudHistorial(
            solicitud_id=s.id,
            accion='aprobado',
            usuario=session.get('usuario'),
            nota=request.form.get('nota')
        )
    )

    db.session.commit()
    flash('Solicitud aprobada', 'success')
    return redirect(url_for('dashboard'))


@app.route('/solicitud/<int:id>/rechazar', methods=['POST'])
@login_required
@rol_required('admin', 'soporte')
def rechazar_solicitud(id):
    s = Solicitud.query.get_or_404(id)
    s.estado = 'rechazado'

    db.session.add(
        SolicitudHistorial(
            solicitud_id=s.id,
            accion='rechazado',
            usuario=session.get('usuario'),
            nota=request.form.get('nota')
        )
    )

    db.session.commit()
    flash('Solicitud rechazada', 'warning')
    return redirect(url_for('dashboard'))


# ================== WEBHOOK (EJEMPLO) ==================
@app.route('/webhook/solicitudes', methods=['POST'])
def webhook_solicitudes():
    # 🔐 Seguridad básica
    if request.headers.get('X-API-KEY') != app.config['WEBHOOK_API_KEY']:
        abort(403)

    data = request.json

    # 🔥 AQUÍ pegarás tu webhook real cuando lo tengas
    solicitud = Solicitud(
        request_id=data.get('request_id'),
        tipo=data.get('tipo'),
        estado='pendiente',
        cliente_nombre=data['cliente']['nombre'],
        cliente_email=data['cliente']['email'],
        pedido_id=data['pedido']['pedido_id'],
        razon=data.get('razon'),
        raw_data=data
    )

    db.session.add(solicitud)
    db.session.commit()

    return {'status': 'ok'}, 200


# ================== INIT ==================
@app.route('/init-db')
def init_db():
    db.create_all()
    return 'Base de datos creada'


@app.route('/crear-usuarios')
def crear_usuarios():
    if Usuario.query.first():
        return 'Usuarios ya existen'

    for u, r in [('admin', 'admin'), ('soporte', 'soporte')]:
        user = Usuario(usuario=u, rol=r)
        user.set_password('1234')
        db.session.add(user)

    db.session.commit()
    return 'Usuarios creados'


# ================== RUN ==================
if __name__ == '__main__':
    app.run(debug=True)
