# Sesión 03 — SQLAlchemy ORM + Alembic Migrations

**Fecha:** 2026-05-14
**Tema:** Mapeo objeto-relacional con SQLAlchemy y control de versiones de esquema con Alembic

---

## Resumen de la sesión

Esta clase fue sobre cómo dejar de escribir SQL crudo y empezar a trabajar con bases de datos usando Python puro. La idea central es que SQLAlchemy ORM te permite definir tus tablas como clases de Python — eso es lo que llaman un "modelo" — y el ORM se encarga de traducir todo a SQL por debajo.

La segunda parte fue sobre Alembic, que es la herramienta de migraciones que acompaña a SQLAlchemy. Básicamente es como un control de versiones para el esquema de tu base de datos: cada vez que cambias un modelo (agregas una columna, creas una tabla, etc.), generas una migración que sabe cómo aplicar ese cambio y también cómo revertirlo.

El esquema que trabajamos fue un sistema de gestión de tareas con tres tablas: `teams`, `users` y `tasks`, con relaciones entre ellas. En los ejercicios extendimos el esquema agregando una tabla `comments`.

---

## Conceptos clave cubiertos

- Qué es un ORM y por qué usarlo en lugar de SQL crudo
- Cómo definir modelos con SQLAlchemy (`Base`, `Column`, tipos de datos)
- Cómo declarar relaciones entre modelos (`ForeignKey`, `relationship`, `back_populates`)
- Operaciones básicas de CRUD usando la sesión de SQLAlchemy (`add`, `commit`, `query`, `delete`)
- Diferencia entre `session.add()` y `session.commit()`
- Qué es Alembic y cómo genera migraciones con `autogenerate`
- Cómo funciona `upgrade()` y `downgrade()` en una migración
- Cómo hacer rollback de una migración con `command.downgrade(cfg, "-1")`
- Cascadas: qué pasa con los registros relacionados cuando borras un padre

---

## Conceptos relacionados

- [SQLAlchemy ORM](../concepts/sqlalchemy-orm.md) — cómo funcionan los modelos, la sesión y las queries
- [Alembic Migrations](../concepts/alembic-migrations.md) — ciclo de vida de una migración, upgrade y downgrade
- [ORM Relationships](../concepts/orm-relationships.md) — `relationship()`, `back_populates`, cascadas

---

## Lo que entendí bien

- La diferencia entre `add()` y `commit()`: `add()` es como poner algo en un carrito de compras (pendiente en la sesión), y `commit()` es cuando realmente pagas y el cambio queda guardado en la base de datos.
- Por qué las migraciones tienen dos funciones (`upgrade` y `downgrade`): necesitas poder ir hacia adelante y hacia atrás sin perder control del esquema.
- El cascade `"all, delete-orphan"` en una relación padre-hijo asegura que cuando borras el padre, los hijos se borran automáticamente — sin dejar datos huérfanos.

## Lo que todavía me genera dudas

- Cuándo usar `session.flush()` versus `session.commit()` — flush parece útil cuando necesitas el ID del objeto antes de hacer commit.
- Cómo Alembic detecta los cambios automáticamente con `autogenerate` — qué pasa si el modelo y la base de datos están desincronizados por cambios manuales.
- Cómo manejar migraciones en un equipo donde varias personas modifican modelos al mismo tiempo (¿conflictos?).

## Preguntas

- Si hago downgrade de una migración y el downgrade borra una columna, ¿hay alguna forma de recuperar esos datos?
- ¿Se puede usar Alembic con una base de datos que ya existe y tiene datos?
- ¿Alembic funciona igual con Oracle que con PostgreSQL?

---

## Recursos usados

- Esquema base: `01_setup_schema.sql` — tablas `teams`, `users`, `tasks` con datos de prueba
- Notebook de clase: `03_sqlalchemy_models.ipynb`
- Ejercicios: [`lesson-03-exercises.md`](../sql_challenges/lesson-03-exercises.md)
- Diagrama del esquema: [`lesson-03-schema.md`](../diagrams/lesson-03-schema.md)
