# Challenge 04 — Window Functions

## Tema
Consultas con funciones de ventana para rankear empleados por salario dentro de cada departamento.

## Conceptos practicados
- `DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...)` — ranking sin saltos en caso de empate
- Diferencia entre `DENSE_RANK`, `RANK` y `ROW_NUMBER`
- `WITH` (CTE) — Common Table Expressions para estructurar consultas complejas
- `PARTITION BY` — aplicar la función de ventana por grupo

## Tablas utilizadas
- `employee` (name, salary, department_id)
- `department` (department_id, department_name)

## Objetivo
Obtener los 3 salarios más altos por departamento, incluyendo empates.

## Solución
Ver [solution.sql](./solution.sql)
