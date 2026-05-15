# ORM Relationships

## Mi entendimiento

Las relaciones en SQLAlchemy ORM te permiten navegar entre objetos relacionados usando atributos de Python, sin tener que escribir JOINs manualmente. El ORM genera el JOIN por debajo cuando accedes a la relación.

Hay dos partes para definir una relación:
1. `ForeignKey(...)` en la columna — esto es la restricción a nivel de base de datos.
2. `relationship(...)` en la clase — esto es la navegación a nivel de Python.

### Relación uno-a-muchos (el caso más común)

Un `Team` tiene muchos `User`. Un `User` pertenece a un `Team`.

```python
class Team(Base):
    __tablename__ = 'teams'

    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False)

    # Lado "uno": acceder a todos los usuarios del equipo
    users = relationship('User', back_populates='team')


class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    username = Column(String(50), nullable=False)
    team_id = Column(Integer, ForeignKey('teams.id'))  # FK en la tabla del "muchos"

    # Lado "muchos": acceder al equipo del usuario
    team = relationship('Team', back_populates='users')
```

Con esto puedes hacer:

```python
equipo = session.query(Team).filter_by(name="Engineering").first()
for usuario in equipo.users:
    print(usuario.username)  # Sin escribir ningún JOIN
```

### `back_populates` vs `backref`

- `back_populates` es explícito: defines el atributo en ambos lados manualmente. Es más claro y recomendado.
- `backref` crea el atributo del otro lado automáticamente — más conciso pero menos visible al leer el código.

### Cascadas

Las cascadas controlan qué pasa con los objetos relacionados cuando haces una operación en el padre.

```python
# Si borras un Task, también se borran todos sus Comment
comments = relationship('Comment', back_populates='task', cascade='all, delete-orphan')
```

Opciones comunes:
- `save-update`: cuando agregas el padre a la sesión, los hijos también se agregan (es el default).
- `delete`: cuando borras el padre, los hijos también se borran.
- `delete-orphan`: si desconectas un hijo del padre (sin borrarlo), el hijo se borra automáticamente.
- `all, delete-orphan`: la combinación más estricta — útil para objetos que no tienen sentido sin su padre.

### Relación muchos-a-muchos

Para esto se necesita una tabla intermedia (tabla de asociación):

```python
# Tabla de asociación (sin clase propia si es simple)
user_projects = Table(
    'user_projects',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id')),
    Column('project_id', Integer, ForeignKey('projects.id')),
)

class User(Base):
    ...
    projects = relationship('Project', secondary=user_projects, back_populates='users')

class Project(Base):
    ...
    users = relationship('User', secondary=user_projects, back_populates='projects')
```

### Lazy loading vs eager loading

Por default, SQLAlchemy usa lazy loading: solo ejecuta el query de la relación cuando realmente accedes al atributo. Si necesitas cargar todo de una vez para evitar el problema N+1:

```python
# Eager loading: trae users junto con el query de teams
equipos = session.query(Team).options(joinedload(Team.users)).all()
```

## Por qué importa

Sin relaciones tendrías que hacer JOINs a mano en cada query. Con `relationship()`, el código queda más legible y la lógica de navegación entre entidades vive en el modelo, no dispersa por todo el código.

## Conceptos relacionados

- [SQLAlchemy ORM](sqlalchemy-orm.md) — la base sobre la que se construyen las relaciones
- [Alembic Migrations](alembic-migrations.md) — las relaciones generan FK constraints que Alembic incluye en las migraciones
