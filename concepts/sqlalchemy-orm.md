# SQLAlchemy ORM

## Mi entendimiento

SQLAlchemy ORM (Object-Relational Mapper) es una capa de abstracción que te permite trabajar con una base de datos relacional usando clases y objetos de Python en lugar de escribir SQL directamente. La idea es que cada tabla de la base de datos se representa como una clase, y cada fila de esa tabla es una instancia de esa clase.

Hay tres piezas fundamentales:

**1. El modelo (la clase)**
Defines una clase que hereda de `Base` (que se obtiene de `declarative_base()`). Cada atributo de clase que uses con `Column(...)` se convierte en una columna en la tabla.

```python
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    username = Column(String(50), nullable=False, unique=True)
    email = Column(String(100), nullable=False)
    team_id = Column(Integer, ForeignKey('teams.id'))
```

**2. El engine y la sesión**
El `engine` es la conexión a la base de datos. La `Session` es el intermediario entre tu código Python y la base de datos — todas las operaciones (insertar, consultar, borrar) pasan por la sesión.

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine("sqlite:///app.db")
Session = sessionmaker(bind=engine)
session = Session()
```

**3. Las operaciones CRUD**

```python
# CREATE
nuevo_usuario = User(username="alice", email="alice@example.com")
session.add(nuevo_usuario)
session.commit()

# READ
usuario = session.query(User).filter_by(username="alice").first()

# UPDATE
usuario.email = "alice_nueva@example.com"
session.commit()

# DELETE
session.delete(usuario)
session.commit()
```

## Por qué importa

- **Portabilidad:** el mismo código Python funciona con PostgreSQL, SQLite, MySQL u Oracle — solo cambias la cadena de conexión del engine.
- **Seguridad:** el ORM parametriza automáticamente las queries, eliminando el riesgo de SQL injection.
- **Mantenibilidad:** es más fácil leer código Python que SQL embebido en strings. Los modelos documentan el esquema en el mismo lugar donde vive la lógica.
- **Productividad:** no necesitas escribir JOINs manualmente para navegar relaciones — el ORM lo hace por ti a través de `relationship()`.

## Diferencia entre `add()` y `commit()`

Esta es una de las cosas más importantes de entender:

- `session.add(objeto)` agrega el objeto a la sesión — lo pone en estado "pendiente". No hay ningún SQL ejecutado todavía.
- `session.commit()` es cuando se ejecuta el SQL de verdad y los cambios quedan guardados permanentemente en la base de datos.
- `session.flush()` es un término medio: ejecuta el SQL contra la base de datos pero sin cerrar la transacción. Útil cuando necesitas el ID generado de un objeto antes de hacer commit.

## Conceptos relacionados

- [Alembic Migrations](alembic-migrations.md) — cómo versionar los cambios al esquema que defines con tus modelos
- [ORM Relationships](orm-relationships.md) — cómo conectar modelos entre sí con `relationship()`
