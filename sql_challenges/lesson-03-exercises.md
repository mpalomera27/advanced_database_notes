# Ejercicios — Lección 03: SQLAlchemy ORM + Alembic Migrations

---

## Ejercicio 1 — Diseño de Modelo: tabla `comments` (10 min)

### El problema

El sistema de tareas necesita una tabla `comments`. Cada comentario pertenece a una tarea y a un usuario. Hay que crear el modelo SQLAlchemy con los campos requeridos y definir las relaciones correctamente.

### Mi razonamiento

Primero identifico las relaciones:
- Un comentario pertenece a **una** tarea → `task_id` como FK hacia `tasks.id`
- Un comentario pertenece a **un** usuario → `user_id` como FK hacia `users.id`
- Una tarea puede tener **muchos** comentarios → relación inversa en `Task`
- Un usuario puede haber escrito **muchos** comentarios → relación inversa en `User`

El campo `content` no puede ser NULL porque un comentario vacío no tiene sentido. `created_at` lo maneja automáticamente el ORM con `default=datetime.utcnow`.

Para la cascada: si se borra una tarea, sus comentarios no tienen razón de existir → `cascade="all, delete-orphan"` en el lado de `Task`.

### Solución

```python
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

class Comment(Base):
    __tablename__ = 'comments'

    id         = Column(Integer, primary_key=True)
    task_id    = Column(Integer, ForeignKey('tasks.id'), nullable=False)
    user_id    = Column(Integer, ForeignKey('users.id'), nullable=False)
    content    = Column(String(1000), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Navegación hacia el padre
    task = relationship('Task', back_populates='comments')
    user = relationship('User', back_populates='comments')


# Modificaciones necesarias en los modelos existentes:

class Task(Base):
    # ... campos existentes ...

    # Agregar esta relación:
    comments = relationship('Comment', back_populates='task', cascade='all, delete-orphan')


class User(Base):
    # ... campos existentes ...

    # Agregar esta relación:
    comments = relationship('Comment', back_populates='user')
```

### Respuestas a las preguntas

**1. ¿Qué relaciones debe tener `Comment`?**
Debe tener dos relaciones many-to-one: una hacia `Task` (el comentario pertenece a una tarea) y una hacia `User` (el comentario lo escribió un usuario). Se declaran con `relationship('Task', ...)` y `relationship('User', ...)`.

**2. ¿Debería `Task` tener una relación `comments`?**
Sí. Definirla en `Task` con `back_populates='task'` es lo que permite hacer `mi_tarea.comments` y obtener la lista de comentarios directamente. Sin esto, la relación es de un solo sentido y perderías la navegación más natural.

**3. ¿Qué debería pasar con los comentarios cuando se borra una tarea?**
Deberían borrarse en cascada. Un comentario sobre una tarea que ya no existe no tiene sentido dejarlo en la base de datos (serían datos huérfanos). Se maneja con `cascade="all, delete-orphan"` en la relación `Task.comments`. A nivel SQL esto equivale a `ON DELETE CASCADE` en la FK constraint.

---

## Ejercicio 2 — Creación de Migración con Alembic (10 min)

### El problema

Ya definiste el modelo `Comment`. Ahora hay que generar la migración con Alembic usando `autogenerate`, inspeccionar el archivo generado y entender qué hace cada función.

### Mi razonamiento

Alembic compara el estado actual de los modelos (lo que está definido en Python) contra el estado de la base de datos real. Como `comments` no existe todavía en la base de datos, el `autogenerate` debería detectar la nueva tabla y generar un `op.create_table(...)` en `upgrade()` y un `op.drop_table(...)` en `downgrade()`.

Para el bonus del CHECK constraint, Alembic soporta `op.create_check_constraint(...)` — aunque `autogenerate` normalmente no lo detecta automáticamente y hay que agregarlo a mano en el archivo generado.

### Solución

```python
import glob
from alembic import command
from alembic.config import Config

alembic_cfg = Config("alembic.ini")

# 1. Generar la migración automáticamente
command.revision(
    alembic_cfg,
    autogenerate=True,
    message="add comments table"
)

# 2. Listar los archivos de versión para encontrar el nuevo
migration_files = sorted(
    glob.glob('/content/project/alembic/versions/*.py')
)
for f in migration_files:
    print(f)

# 3. Leer el contenido del archivo más reciente
latest = migration_files[-1]
with open(latest) as f:
    print(f.read())
```

El archivo generado debería verse así (aproximado):

```python
"""add comments table

Revision ID: a1b2c3d4e5f6
Revises: <revision_anterior>
Create Date: 2026-05-14 ...
"""

def upgrade():
    op.create_table(
        'comments',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('task_id', sa.Integer(), sa.ForeignKey('tasks.id'), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('content', sa.String(length=1000), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
    )

def downgrade():
    op.drop_table('comments')
```

**Bonus — agregar CHECK constraint a mano:**

```python
def upgrade():
    op.create_table(
        'comments',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('task_id', sa.Integer(), sa.ForeignKey('tasks.id'), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('content', sa.String(length=1000), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.CheckConstraint("content != ''", name='ck_comments_content_not_empty'),
    )

def downgrade():
    op.drop_table('comments')
    # drop_table ya elimina los constraints asociados automáticamente
```

### Respuestas a las preguntas

**1. ¿Qué hace `upgrade()`?**
Aplica el cambio hacia adelante: en este caso, crea la tabla `comments` con todas sus columnas y constraints de FK. Cuando corres `alembic upgrade head` o `command.upgrade(cfg, "head")`, se ejecuta esta función.

**2. ¿Qué hace `downgrade()`?**
Revierte el cambio: elimina la tabla `comments`. Es el "deshacedor" de lo que hizo `upgrade()`. Cada migración tiene que saber cómo deshacerse a sí misma.

**3. ¿Qué pasa si haces downgrade de esta migración?**
La tabla `comments` se elimina completamente de la base de datos. Cualquier dato que hubiera en esa tabla se pierde para siempre — no hay papelera de reciclaje. Por eso es importante pensar bien los downgrades cuando hay datos en producción.

---

## Ejercicio 3 — CRUD Challenge (10 min)

### El problema

Escribir un script que: cree el equipo `"DevOps"`, cree el usuario `"diana_ops"`, cree 3 tareas con diferentes prioridades, imprima el conteo de tareas, cierre una tarea, y borre la de menor prioridad.

### Mi razonamiento

El orden importa: primero creo el equipo, luego el usuario (necesita `team_id`), luego las tareas (necesitan `assigned_to`). Como el ORM maneja identidades, necesito hacer `flush()` después de crear el equipo y el usuario para obtener sus IDs antes de referenciarlos en los objetos siguientes.

Para las prioridades, como la tabla no tiene una columna `priority`, las represento en `description`. Las ordeno mentalmente como HIGH > MEDIUM > LOW y al final borro la LOW.

### Solución

```python
from sqlalchemy import create_engine, func
from sqlalchemy.orm import sessionmaker

engine = create_engine("sqlite:///app.db")
session = sessionmaker(bind=engine)()

# 1. Crear el equipo DevOps
devops = Team(name="DevOps", description="Equipo de infraestructura y despliegue")
session.add(devops)
session.flush()  # flush para obtener devops.id antes del commit

# 2. Crear el usuario diana_ops
diana = User(
    username="diana_ops",
    email="diana@example.com",
    full_name="Diana Ops",
    team_id=devops.id
)
session.add(diana)
session.flush()  # flush para obtener diana.id

# 3. Crear 3 tareas con distintas prioridades
tarea_alta = Task(
    title="Migrar base de datos a producción",
    description="Prioridad: ALTA — impacta el release de mañana",
    status="open",
    assigned_to=diana.id
)
tarea_media = Task(
    title="Configurar alertas de monitoreo",
    description="Prioridad: MEDIA — importante pero no bloqueante",
    status="open",
    assigned_to=diana.id
)
tarea_baja = Task(
    title="Actualizar documentación de deploys",
    description="Prioridad: BAJA — puede esperar a la siguiente semana",
    status="open",
    assigned_to=diana.id
)

session.add_all([tarea_alta, tarea_media, tarea_baja])
session.commit()

# 4. Imprimir el conteo de tareas
conteo = session.query(func.count(Task.id)).filter_by(assigned_to=diana.id).scalar()
print(f"Tareas asignadas a {diana.username}: {conteo}")

# 5. Cerrar la tarea de mayor prioridad
tarea_alta.status = "closed"
session.commit()
print(f"Tarea '{tarea_alta.title}' cerrada.")

# 6. Borrar la tarea de menor prioridad
session.delete(tarea_baja)
session.commit()
print(f"Tarea '{tarea_baja.title}' eliminada.")

# Verificar estado final
tareas_activas = session.query(Task).filter_by(assigned_to=diana.id).all()
for t in tareas_activas:
    print(f"  - [{t.status}] {t.title}")
```

**Salida esperada:**
```
Tareas asignadas a diana_ops: 3
Tarea 'Migrar base de datos a producción' cerrada.
Tarea 'Actualizar documentación de deploys' eliminada.
  - [closed] Migrar base de datos a producción
  - [open] Configurar alertas de monitoreo
```

---

## Ejercicio 4 — Migration Rollback (5 min)

### El problema

Se aplicó una migración que agrega la columna `estimated_hours` a la tabla `tasks`. Esa columna fue un error (o ya no la necesitas). Hay que hacer rollback programáticamente.

### Mi razonamiento

El comando `downgrade("-1")` le dice a Alembic que retroceda exactamente una versión desde el estado actual. Alembic busca cuál es la migración activa en la tabla `alembic_version`, encuentra la función `downgrade()` de esa migración, y la ejecuta.

La función `downgrade()` de esa migración debería contener `op.drop_column('tasks', 'estimated_hours')`.

### Solución

```python
from alembic import command
from alembic.config import Config

alembic_cfg = Config("alembic.ini")

# Ver el estado actual antes de hacer rollback
command.current(alembic_cfg)

# Revertir la última migración
command.downgrade(alembic_cfg, "-1")

# Verificar que se revirtió correctamente
command.current(alembic_cfg)
```

El archivo de migración que se revierte sería algo así:

```python
def upgrade():
    op.add_column('tasks', sa.Column('estimated_hours', sa.Float(), nullable=True))

def downgrade():
    op.drop_column('tasks', 'estimated_hours')
```

### Respuestas a las preguntas

**1. ¿Qué pasa con la columna?**
La columna `estimated_hours` se elimina de la tabla `tasks`. Alembic ejecuta un `ALTER TABLE tasks DROP COLUMN estimated_hours` (o el equivalente en el dialecto SQL que estés usando).

**2. ¿Qué pasa con los datos?**
Todos los valores que hubiera en `estimated_hours` se pierden permanentemente. No hay forma de recuperarlos después del downgrade (a menos que tengas un backup de la base de datos). Por eso antes de hacer rollback en producción siempre conviene tener un snapshot del estado de la base de datos.

---

## Ejercicio 5 — Preguntas Conceptuales (5 min)

### 1. ¿Por qué usar ORM en lugar de SQL crudo?

El ORM te da portabilidad (el mismo código funciona con distintos motores de base de datos), protección automática contra SQL injection (parametriza los valores), y código más mantenible porque el esquema vive junto con la lógica de negocio. También puedes navegar relaciones usando atributos de Python en lugar de escribir JOINs. La contrapartida es que a veces el SQL que genera el ORM es menos eficiente que uno escrito a mano — pero para el 90% de los casos de uso no importa.

### 2. ¿Por qué usar migraciones?

Porque la base de datos en producción tiene datos reales que no puedes borrar y recrear cada vez que cambias el esquema. Las migraciones te permiten hacer cambios incrementales y controlados. También sirven como historial: puedes ver exactamente qué cambió y cuándo, igual que el historial de commits de Git para el código.

### 3. ¿Cuándo harías rollback?

Cuando una migración que ya se aplicó en producción tiene un error, rompe algo que no debería, o simplemente fue un cambio incorrecto. El rollback te permite volver al estado anterior del esquema rápidamente sin tener que reescribir la base de datos a mano. También se usa en desarrollo cuando quieres probar la migración en ambos sentidos para asegurarte de que el `downgrade()` funciona correctamente.

### 4. ¿Diferencia entre `add()` y `commit()`?

`session.add(objeto)` registra el objeto en la sesión como pendiente — es como poner algo en un carrito de compras. En este punto no hay ningún SQL ejecutado. `session.commit()` es el momento en que se ejecuta el SQL de verdad, la transacción se cierra, y los cambios quedan guardados permanentemente en la base de datos. Si llamas `session.rollback()` antes del commit, todos los cambios pendientes se descartan.

### 5. ¿Por qué son útiles las relaciones?

Las relaciones te permiten navegar entre objetos relacionados usando atributos de Python (`tarea.usuario`, `equipo.usuarios`) en lugar de tener que escribir JOINs explícitos en cada consulta. El ORM genera el SQL necesario automáticamente. También hacen el código más legible: `tarea.comentarios` dice exactamente lo que significa, mientras que un JOIN manual requiere que leas y decodifiques el SQL para entender la intención. Además, con las cascadas puedes definir el comportamiento al borrar o modificar objetos padre de forma declarativa.
