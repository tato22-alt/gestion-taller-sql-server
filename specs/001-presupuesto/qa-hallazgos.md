# Hallazgos de verificación 001 — Presupuesto

**Estado:** pendiente de decisión del dueño del negocio
**Origen:** pase de verificación tras implementar los bloques A, B y C (T001–T010)
**Spec:** `spec.md` · **Plan:** `plan.md` · **Constitución:** v3.0.0

Este documento no decide nada. Registra lo que la implementación descubrió, para que se
corrija la spec antes de seguir — principio X: la spec precede a la migración, y cuando la
implementación descubre que la spec estaba equivocada se corrige la spec, no se deja el DDL
como única verdad.

Cada hallazgo dice: qué se rompe, en qué caso real, y qué requisito toca. Las opciones están
para elegir, no aplicadas.

---

## Estado real de lo verificado

Corrido y verificado en Supabase, a mano, desde el editor SQL:

| Tarea | Verificado con | Resultado |
|---|---|---|
| T001 | Migración sobre base vacía | corre limpia |
| T002 | Insert sólo con nombre | `nombre_norm` = `JUAN PÉREZ` |
| T003 | `aa 123-bb` vs `AA123BB` | colisionan, unicidad activa |
| T004 | `AAR222` / `AA000AA` / `X1` | true / true / false; patente rara se guarda |
| T005 | Insert sin cliente, sin vehículo, sin origen | entra, defaults correctos |
| T006 | Dos conceptos fuera de orden | vuelven ordenados por `orden` |
| T007 | `set role anon` + select/insert | 0 filas / bloqueado por RLS |
| T008 | `set role anon` + select | `42501 permission denied` |
| T009 | Vista sobre trabajo con 2 conceptos | 23000 + 1000 = 24000, derivado |
| T010 | Las 7 preguntas | 6 responden; la 3 falla (hallazgo 1) |

Esa tabla es el registro de la verificación **manual**, que resultó no ser confiable (ver H10).
La verificación que vale hoy es `qa-001-verificacion.sql`: 41 comprobaciones en una sola
consulta. Última corrida sobre PostgreSQL 16 con las nueve migraciones aplicadas desde cero:
**38 PASA, 3 ABIERTO, 0 FALLA**, repetible y sin dejar filas.

---

## Hallazgos

### H1 — La búsqueda por nombre no encuentra nombres con tilde

**Qué pasa.** La pregunta 3 de la spec devuelve vacío buscando `perez` cuando el cliente es
`Juan Pérez`. `ILIKE` es insensible a mayúsculas, no a acentos.

**Caso real.** Alguien busca "perez" desde el teléfono, sin tilde, y el sistema dice que ese
cliente no existe. Lo carga de nuevo. Ahora hay dos "Pérez".

**Toca.** Pregunta 3, criterio de aceptación 5, y agrava el riesgo de duplicados de D5.

**Opciones.**

1. **Dejarlo.** Hay que buscar con tilde. Es lo que dice la spec hoy, literal.
2. **Agregar `unaccent`** y redefinir `clientes.nombre_norm` para que también saque acentos.
   Cuesta una migración que recrea la columna generada (Postgres no deja alterar su
   expresión), sobre una tabla que ya tiene RLS y permisos — hay que verificar que no se
   pierdan. Es una enmienda a RF-009 y al esquema de `clientes` del plan.

---

### H2 — Nunca se probó que un usuario autenticado pueda leer y escribir · RESUELTO

**Qué pasa.** Se verificó exhaustivamente que `anon` no puede hacer nada. No se verificó
nunca lo contrario: que `authenticated` sí puede. Las pruebas se corrieron como `postgres`,
que bypassea RLS y no prueba ninguna política.

**Caso real.** Se conecta la página, entra el primer usuario real, y no ve nada — o no puede
guardar. Un `GRANT` de más en el `REVOKE` de T008, una política mal escrita, o una columna
`IDENTITY` que necesita permiso sobre su secuencia, y no nos enteramos hasta producción.

**Toca.** T007, T008, T009 — los tres se dieron por cerrados sin esta prueba. D8.

**Qué falta correr** (no cambia nada, sólo verifica):

```sql
set role authenticated;
select * from vw_presupuestos;              -- tiene que devolver filas
select * from trabajos;                      -- tiene que devolver filas
insert into clientes (nombre) values ('Prueba autenticado');  -- tiene que funcionar
reset role;
delete from clientes where nombre = 'Prueba autenticado';
```

**Resuelto.** Se corrió a mano contra Supabase: `authenticated` lee la vista y escribe sin
problema. Además quedó automatizado en `qa-001-verificacion.sql`, verificaciones 36 y 37, así
que se vuelve a comprobar en cada corrida y no depende de que alguien se acuerde.

---

### H3 — La validación de patente da falso negativo si le llega la patente cruda

**Qué pasa.** `fn_es_formato_patente_valido` espera la patente ya normalizada. Con `aar222`
en minúscula devuelve `false`. Lo descubrimos probando: pasó exactamente eso.

**Caso real.** La página la usa "para advertir mientras se tipea" (D3) — o sea, sobre lo que
la persona está escribiendo, que es justamente texto crudo. Va a marcar como inválida toda
patente escrita en minúscula o con guión. La gente aprende a ignorar la advertencia, y
entonces la advertencia no sirve para nada.

**Toca.** RF-022, D3.

**Opciones.**

1. **Dejarlo** y documentar que quien llama tiene que normalizar antes.
2. **Que la función normalice internamente** antes de comparar. Es un cambio chico
   (`create or replace`), no toca ninguna tabla, y hace que la función sea correcta para el
   único uso que la spec le da.

---

### H4 — "Un solo acto" no es atómico

**Qué pasa.** El criterio de aceptación 1 pide registrar cliente + vehículo + presupuesto
"en un solo acto". Contra Supabase eso son tres llamadas REST separadas: tres transacciones
distintas. No hay nada que las agrupe.

**Caso real.** Se corta el wifi del taller entre la segunda y la tercera. Queda un cliente y
un vehículo creados, sin presupuesto. Nadie lo ve nunca, y el próximo presupuesto de ese auto
"reutiliza" un vehículo huérfano. Con dos o tres de estos por mes, la base se ensucia sola.

**Toca.** Criterio de aceptación 1, escenario E1.

**Opciones.**

1. **Dejarlo** y aceptar que la app haga las tres llamadas, con la basura ocasional.
2. **Una función RPC** (`fn_registrar_presupuesto`) que reciba todo y lo inserte en una sola
   transacción. Supabase la expone como endpoint. No es lógica de negocio escondida en un
   trigger (principio VI): es una operación que alguien invoca explícitamente. Sería una
   tarea nueva del plan, no está en `tasks.md`.

---

### H5 — RF-020 no está garantizado: un número borrado se puede reusar

**Qué pasa.** RF-020 dice que un número emitido no se reutiliza nunca, "ni siquiera si el
presupuesto se borra". El índice único sólo impide dos filas simultáneas con el mismo número.
Si se borra el trabajo 16043, el 16043 queda libre otra vez.

**Caso real.** Se carga un presupuesto mal, se borra, se vuelve a cargar. Dos papeles
distintos con el mismo número, y el segundo pisó al primero en el historial. Es exactamente
el riesgo que la herramienta actual mitiga con `maxEmitido`, que nunca retrocede.

**Toca.** RF-020. El plan delega la *asignación* al feature 002, pero la *garantía de no
reúso* es estructural y no está.

**Opciones.**

1. **Es del feature 002.** El que asigne números lleva el máximo histórico, como hace hoy la
   herramienta. La base no lo garantiza sola.
2. **Un registro de números emitidos** en esta feature: una tabla a la que sólo se agrega, y
   de la que nunca se borra. Cuesta una tabla que la spec no pidió (principio V pide
   justificar cada estructura).

Nota: el número **16043 ya está quemado** por los datos de prueba (ver H9).

---

### H6 — El índice de búsqueda de clientes no lo usa ninguna consulta

**Qué pasa.** T002 creó un índice de trigramas sobre `clientes.nombre_norm`. La consulta de
la pregunta 3 filtra por `vw_presupuestos.cliente_actual`, que es `clientes.nombre` — otra
columna. Postgres no puede usar ese índice para esa consulta. El índice está muerto.

**Caso real.** Con tres personas y unos miles de presupuestos no se va a notar nunca. Pero es
una inconsistencia entre lo que el plan dijo que hacía falta y lo que las consultas hacen.

**Toca.** Sección "Índices" del plan, pregunta 3.

**Opciones.** Que la consulta filtre por `nombre_norm` (y entonces hay que exponerlo en la
vista), o mover el índice a `nombre`. Se resuelve junto con H1, porque si se agrega `unaccent`
la normalización cambia igual.

---

### H7 — La pregunta 7 deja afuera los presupuestos sin fecha

**Qué pasa.** La consulta mensual filtra `where fecha_presupuesto is not null`. RF-008 dice
que la fecha puede faltar.

**Caso real.** El total de un mes no cuadra con la suma de los presupuestos de ese mes, porque
algunos no tienen fecha y desaparecen del conteo sin avisar.

**Toca.** Pregunta 7, RF-008.

**Opciones.** Dejarlo (y documentar que el corte mensual sólo cuenta los fechados), o devolver
una fila aparte para los sin fecha. Es decisión de negocio, no técnica.

**Aparte, menor:** `date_trunc('month', fecha_presupuesto)` devuelve `timestamptz`
(`2026-09-01 00:00:00+00`), no una fecha. Invita justo a la confusión que D6 quiere evitar.
Conviene cerrarlo con `::date`.

---

### H8 — No hay registro de qué migraciones se corrieron

**Qué pasa.** Las migraciones se pegan a mano en el panel. Nada anota cuáles se aplicaron. La
única fuente es esta conversación.

**Caso real.** En dos semanas nadie sabe si la base tiene T008 o no. Se vuelve a correr una
migración y falla a la mitad, o peor: se saltea una y queda una tabla sin RLS. El plan ya
marca esto como riesgo abierto ("conviene verificarlo en cada migración") pero no lo resuelve.

**Toca.** Proceso, no esquema. La restricción de que no hay salida de red viene del entorno.

**Opciones.** Una tabla `migraciones_aplicadas` que cada migración escribe al final; o llevar
el registro fuera de la base, a mano, en el repo. La primera es autoverificable y cuesta poco.

---

### H9 — La base tiene datos de prueba adentro

**Qué pasa.** Quedaron: cliente `Juan Pérez` (id 1), vehículo `x1-rara` (id 3), trabajo
`id_trabajo=1` con número **16043** y dos conceptos por 23000.

**Caso real.** Si esto sigue ahí cuando entren los datos reales, el 16043 está ocupado por un
presupuesto que no existe, y el primer reporte mensual arranca con 24000 de más.

**Qué falta.** Limpiarlos antes de que entre nada real, y decidir si los datos de prueba
vuelven de forma controlada en T016 (que ya existe en `tasks.md` justamente para eso).

---

### H10 — El método de verificación usado hasta acá era inválido · RESUELTO

**Qué pasa.** El editor SQL de Supabase muestra **sólo el resultado de la última sentencia**
de un bloque. Durante T001–T010 se verificó pegando bloques de varias sentencias y mirando un
único resultado: el de la última. Todo lo anterior de cada bloque quedó sin mirar.

**Caso real.** No es hipotético, pasó tres veces en esta implementación: se dio por buena una
tabla que todavía no existía, se leyó como `false` una función que en realidad no se había
ejecutado, y se confirmó un `insert` mirando el `Success` de otra línea. Cualquiera de esas
podría haber sido una falla real dada por buena.

**Resuelto.** Todo el QA es ahora **una sola función que devuelve una tabla de veredictos**
(`qa-001-verificacion.sql`): una fila por verificación, con PASA / FALLA / ABIERTO. La única
sentencia que devuelve resultados es la última, así que la limitación del editor deja de
esconder nada.

**Regla que queda:** ninguna verificación de este repositorio se hace con sentencias sueltas
en un bloque. Se agrega como verificación a la función de QA, y se corre entera.

---

## Lo que ya está previsto y no es hallazgo

`tasks.md` ya contempla la mayor parte del QA que falta, y no hace falta inventar tareas:

- **T016** — datos de prueba que cubren los seis escenarios.
- **T017** — verificación de los siete criterios, registrando cómo se probó cada uno.
- **T018** — diccionario de datos: zonas horarias, campos derivados, qué no toca la importación.

Tres criterios de aceptación siguen **sin probar** y sólo se pueden probar en T016/T017, con
datos que hoy no existen:

- **Criterio 3** — un segundo presupuesto sobre la misma patente reutiliza el vehículo.
- **Criterio 4** — corregir el nombre de un cliente no altera un presupuesto ya emitido (hoy
  imposible de probar: el único trabajo cargado tiene los `txt_*` en nulo).
- **Criterio 6** — el CSV importa completo y reimportarlo no duplica (bloque D, sin empezar).

---

## Propuesta de orden

1. ~~Correr H2~~ — hecho: pasa, y quedó automatizado.
2. Correr `qa-001-verificacion.sql` contra Supabase, para confirmar que la base real coincide
   con lo verificado en local.
3. Decidir H1, H3, H5, H7 — son enmiendas a la spec, y por el principio X van a la spec antes
   que a una migración.
4. Decidir H4 y H8, que agregan tareas al plan.
5. Limpiar H9 antes de cualquier dato real.
6. Recién entonces, bloque D — y cada tarea nueva suma sus verificaciones a la función de QA.
