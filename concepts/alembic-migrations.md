# Alembic Migrations

## Mi entendimiento

Alembic es la herramienta de migraciones oficial para SQLAlchemy. Su función es rastrear los cambios en el esquema de tu base de datos a lo largo del tiempo, de la misma manera en que Git rastrea los cambios en tu código.

El problema que resuelve es el siguiente: cuando trabajas en equipo o en producción, no puedes simplemente borrar y recrear las tablas cada vez que necesitas cambiar el esquema. Necesitas una forma controlada de aplicar cambios incrementales — y también de revertirlos si algo sale mal.

### Cómo funciona

Alembic maneja una tabla especial en la base de datos llamada `alembic_version` que guarda el ID de la migración actual. Cuando corres `upgrade`, avanza al siguiente estado. Cuando corres `downgrade`, retrocede al anterior.

Cada migración es un archivo Python en la carpeta `alembic/versions/` con dos funciones:

```python
def upgrade():
    # Lo que se hace al aplicar la migración
    op.create_table(
        'comments',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('content', sa.String(1000), nullable=False),
        sa.Column('task_id', sa.Integer(), sa.ForeignKey('tasks.id')),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id')),
        sa.Column('created_at', sa.DateTime(), default=datetime.utcnow),
    )

def downgrade():
    # Lo que se hace al revertir la migración
    op.drop_table('comments')
```

### Generación automática con autogenerate

Lo más útil de Alembic es que puede comparar tus modelos SQLAlchemy actuales contra el estado real de la base de datos y generar el archivo de migración automáticamente:

```python
from alembic import command
from alembic.config import Config

alembic_cfg = Config("alembic.ini")

command.revision(
    alembic_cfg,
    autogenerate=True,
    message="add comments table"
)
```

Esto genera un archivo de versión con las diferencias detectadas. Siempre conviene revisar ese archivo antes de aplicarlo.

### Aplicar y revertir migraciones

```python
# Aplicar todas las migraciones pendientes
command.upgrade(alembic_cfg, "head")

# Revertir la última migración
command.downgrade(alembic_cfg, "-1")

# Revertir dos migraciones atrás
command.downgrade(alembic_cfg, "-2")

# Ir a una versión específica
command.upgrade(alembic_cfg, "abc123def456")
```

## Por qué importa

- **Control de versiones del esquema:** cada cambio queda registrado con un mensaje y un ID. Puedes ver toda la historia de cómo evolucionó tu base de datos.
- **Colaboración en equipo:** todos los desarrolladores aplican las mismas migraciones en el mismo orden — no hay discrepancias entre entornos.
- **Reversibilidad:** si una migración rompe algo en producción, puedes hacer downgrade en segundos en lugar de tratar de arreglar el esquema a mano.
- **Automatización:** puedes integrar `alembic upgrade head` en tu pipeline de deploy para que el esquema se actualice automáticamente al desplegar nueva versión.

## Lo que hay que tener cuidado

- El `downgrade` **borra datos**. Si la migración agrega una columna y el downgrade la elimina, todos los valores de esa columna se pierden para siempre.
- El `autogenerate` no detecta todo. Cambios como renombrar columnas, modificar constraints complejos o cambiar tipos pueden no generarse correctamente y hay que escribirlos a mano.
- Las migraciones deben correr en orden. Si dos personas crean migraciones simultáneamente, puede haber conflictos de rama que hay que resolver.

## Conceptos relacionados

- [SQLAlchemy ORM](sqlalchemy-orm.md) — los modelos que Alembic inspecciona para generar migraciones
- [ORM Relationships](orm-relationships.md) — las relaciones entre modelos también afectan las migraciones (FK constraints, tablas intermedias)
