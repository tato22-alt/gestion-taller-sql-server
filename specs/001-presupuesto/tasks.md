# Tareas 001 — Presupuesto

**Plan:** `specs/001-presupuesto/plan.md` · **Constitución:** v3.0.0 · **Motor:** PostgreSQL sobre Supabase

Cada tarea entrega algo verificable. El orden importa: una tarea no arranca hasta que su dependencia
está verificada.

---

## Bloque A — Esquema

| # | Tarea | Depende | Termina cuando |
|---|---|---|---|
| T001 | Migración inicial: extensiones, convenciones de nombres y `updated_at` | — | La migración corre limpia sobre una base vacía |
| T002 | Tabla `clientes` con `nombre_norm` generada e índice de búsqueda | T001 | Se inserta un cliente sólo con nombre (RF-013) |
| T003 | Tabla `vehiculos` con `patente_norm` generada y única | T001 | `aa 123-bb` y `AA123BB` colisionan como la misma patente |
| T004 | Función de validación de formato de patente, no bloqueante | T003 | Reconoce `AAR222` y `AA000AA`; una patente rara se guarda igual (RF-022) |
| T005 | Tabla `trabajos`: snapshot, `numero_presupuesto` único parcial, `origen` nulo | T002, T003 | Entra un trabajo sin cliente, sin patente y sin origen (RF-008, RF-014) |
| T006 | Tabla `trabajo_items` con `orden` y cascada | T005 | Los conceptos vuelven en el orden en que se cargaron |

## Bloque B — Acceso

| # | Tarea | Depende | Termina cuando |
|---|---|---|---|
| T007 | RLS en las cuatro tablas y políticas de usuario autenticado | T006 | Con la clave anónima no se lee ni se escribe nada (D8) |
| T008 | Permisos sobre vistas y revocación al rol anónimo | T007 | Verificado con una llamada REST real usando la clave anónima |

## Bloque C — Derivación

| # | Tarea | Depende | Termina cuando |
|---|---|---|---|
| T009 | Vista `vw_presupuestos` con totales derivados | T006 | El total sale de los renglones y no de ninguna columna (D2) |
| T010 | Consultas de las siete preguntas de la spec | T009 | Cada una se responde con una sola consulta |

## Bloque D — Importación

> **EN PAUSA — ver H16.** Luciano confirmó que no hay registro histórico: el taller está pasando de
> papel a digital, y el `localStorage` no tiene presupuestos que traer. Estas cinco tareas migran
> cero filas. Se conservan sin empezar, porque vuelven a tener sentido si se cargan presupuestos en
> el navegador antes de que la página se conecte a la base. **No bloquean al feature 002.**

| # | Tarea | Depende | Termina cuando |
|---|---|---|---|
| T011 | Tabla `stg_presupuesto_csv` con las catorce columnas como texto | T001 | Un CSV entero entra crudo sin validar |
| T012 | Función de validación que reporta por número de línea y no escribe | T011 | Detecta número no entero, importe no numérico y detalle sin importe |
| T013 | Función de consolidación: resolver cliente y vehículo, upsert, reemplazo de conceptos | T012, T006 | Un lote válido queda cargado con sus conceptos en orden |
| T014 | Idempotencia y regla de `modificado_en` | T013 | Reimportar no duplica; un CSV viejo no pisa una corrección nueva (RF-018) |
| T015 | Consulta de clientes posiblemente duplicados | T013 | Lista nombres parecidos para revisión manual (riesgo D5) |

## Bloque E — Verificación y cierre

| # | Tarea | Depende | Termina cuando |
|---|---|---|---|
| T016 | Datos de prueba que cubren los seis escenarios de la spec | T009 | Incluye auto nuevo, auto repetido, no concretado y presupuesto sin cliente |
| T017 | Verificación de los siete criterios de aceptación | T010, T014, T016 | Los siete pasan y queda registrado cómo se probó cada uno |
| T018 | Diccionario de datos actualizado | T017 | Documenta zonas horarias, campos derivados y qué no toca la importación |
| T019 | Retirar del repositorio el modelo académico derogado | T017 | Se van `Casos`, `CasoItems.tipo`, el trigger de fecha y `sp_CambiarEstadoCaso` |

---

## Fuera de estas tareas

Conectar la herramienta de presupuesto a la base, y con eso mover la autoridad de la numeración
(RF-021). Es el feature 002 y necesita antes: proyecto de Supabase creado, usuarios dados de alta y
login resuelto en la página, que hoy no tiene ninguno.

**Actualización (H16).** El proyecto de Supabase ya existe y el esquema está corrido y verificado.
Al no haber histórico, el bloque D dejó de ser un requisito previo. Lo que falta para el 002 es:
usuarios de Supabase Auth dados de alta, login en la página, y decidir cómo se asigna el número
—arrancando en 16000 sobre una base vacía, y confirmando en qué número quedó el talonario de papel.
