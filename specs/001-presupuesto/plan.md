# Plan 001 — Presupuesto

**Estado:** borrador, pendiente de aprobación
**Spec:** `specs/001-presupuesto/spec.md`
**Constitución aplicable:** v2.0.0
**Motor:** SQL Server, T-SQL

---

## Decisiones de diseño

Cada una con su alternativa descartada, porque son las que después no se pueden revisar barato.

### D1 — Clave subrogada, número de presupuesto único

`Trabajos` lleva `id_trabajo INT IDENTITY` como clave primaria y `numero_presupuesto INT NULL` con
índice único filtrado sobre los no nulos.

La spec (RF-002) pide que el número del talonario sea el identificador del sistema, y lo es: es único,
es por el que se busca, y es el que se dicta por teléfono. Pero hacerlo clave primaria impediría
registrar un trabajo que llegue sin presupuesto previo — un auto de compañía que entra con la orden ya
emitida, por ejemplo — y el principio IV prohíbe que el esquema impida registrar la realidad. La clave
subrogada cuesta una columna y no cierra ninguna puerta.

### D2 — El total no se almacena

`monto_total` y `subtotal_repuestos` no son columnas: salen de una vista que suma los conceptos y le
agrega la mano de obra. El CSV los trae, pero como valores informativos que se recalculan al importar,
igual que hace la propia herramienta al restaurar.

Principio II. Un total almacenado se desincroniza de sus renglones el día que alguien corrija un
importe por fuera del camino previsto.

### D3 — La patente se normaliza en la base, no se confía en quien la manda

`Vehiculos.patente` guarda lo que llegó, y una columna calculada `PERSISTED` deriva `patente_norm` en
mayúsculas sin espacios, guiones ni puntos. El índice único va sobre la derivada.

La herramienta ya normaliza, pero es un consumidor entre varios y el dato importado del pasado viene
sucio. Una columna calculada persistida no contradice el principio II: no la mantiene una persona, la
mantiene el motor, y no se puede desactualizar.

### D4 — El snapshot de lo impreso vive en el trabajo

`Trabajos` guarda `txt_cliente`, `txt_direccion`, `txt_telefono`, `txt_vehiculo` y `txt_patente`, además
de las referencias a `Clientes` y `Vehiculos`.

No viola el principio V. Lo que decía el papel y el dato maestro de hoy son hechos distintos: corregir un
nombre mal escrito en la ficha de un cliente no puede cambiar lo que dice un presupuesto ya entregado.
Y el texto impreso no es alcanzable por ninguna relación, porque el maestro pudo haber cambiado.

### D5 — Cliente y vehículo se resuelven al importar, con las colisiones que haya

El vehículo se busca por patente normalizada y se crea si no existe. El cliente se busca por nombre
normalizado —recortado, en mayúsculas, con espacios colapsados— y se crea si no existe.

Esto va a generar clientes duplicados cuando el mismo nombre esté escrito de dos maneras. Es
deliberado: RF-019 dice que la importación acepta el pasado como está y no es tarea de la migración
limpiarlo. Fusionar clientes es una operación posterior y manual, y hay que preverla como trabajo real.

Un presupuesto sin nombre de cliente entra con `id_cliente` nulo. Sin patente, con `id_vehiculo` nulo.

### D6 — Fechas: una es local, las otras son UTC

`fecha_presupuesto` es `DATE`: es la fecha que se escribe en el papel, sin hora ni zona.
`creado_en` y `modificado_en` son `DATETIME2(0)` **en UTC**, porque así los emite la herramienta.

Se documenta en el diccionario para que nadie los compare ingenuamente. No se usa `DATETIMEOFFSET`: no
hay más de una zona en juego y agregaría ruido a cada consulta.

---

## Esquema

### `Clientes`

| Columna | Tipo | Nulo | Notas |
|---|---|---|---|
| `id_cliente` | `INT IDENTITY` | no | PK |
| `nombre` | `NVARCHAR(120)` | no | único dato exigido (RF-013) |
| `nombre_norm` | `AS (...) PERSISTED` | no | mayúsculas, recortado, para buscar y deduplicar |
| `telefono` | `NVARCHAR(40)` | sí | |
| `direccion` | `NVARCHAR(200)` | sí | |
| `email` | `NVARCHAR(120)` | sí | no lo captura el presupuesto; queda para la app |
| `cuit` | `NVARCHAR(20)` | sí | ídem |
| `creado_en` | `DATETIME2(0)` | no | `SYSUTCDATETIME()` |

Sin restricción única sobre el nombre: dos clientes pueden llamarse igual. Índice no único sobre
`nombre_norm` para búsqueda por parte del nombre.

### `Vehiculos`

| Columna | Tipo | Nulo | Notas |
|---|---|---|---|
| `id_vehiculo` | `INT IDENTITY` | no | PK |
| `patente` | `NVARCHAR(15)` | no | como llegó |
| `patente_norm` | `AS (...) PERSISTED` | no | **UNIQUE** |
| `descripcion` | `NVARCHAR(120)` | sí | «Ford Ranger», sin separar marca ni modelo (RF-011) |
| `id_cliente_ultimo` | `INT` | sí | FK, sólo para proponer (RF-012) |
| `creado_en` | `DATETIME2(0)` | no | |

### `Trabajos`

| Columna | Tipo | Nulo | Notas |
|---|---|---|---|
| `id_trabajo` | `INT IDENTITY` | no | PK |
| `numero_presupuesto` | `INT` | sí | **único filtrado**, ≥ 16000, `CHECK` de rango |
| `id_cliente` | `INT` | sí | FK |
| `id_vehiculo` | `INT` | sí | FK |
| `fecha_presupuesto` | `DATE` | sí | RF-008: puede faltar |
| `txt_cliente` | `NVARCHAR(120)` | sí | snapshot |
| `txt_direccion` | `NVARCHAR(200)` | sí | snapshot |
| `txt_telefono` | `NVARCHAR(40)` | sí | snapshot |
| `txt_vehiculo` | `NVARCHAR(120)` | sí | snapshot |
| `txt_patente` | `NVARCHAR(15)` | sí | snapshot |
| `monto_mano_obra` | `DECIMAL(12,2)` | no | default 0 |
| `no_concretado` | `BIT` | no | default 0 (RF-015) |
| `origen` | `VARCHAR(12)` | sí | `particular` / `siniestro`; **nulo al nacer** (RF-014) |
| `creado_en` | `DATETIME2(0)` | no | UTC, viene del origen si se importa |
| `modificado_en` | `DATETIME2(0)` | no | UTC, ídem |
| `origen_carga` | `VARCHAR(20)` | no | `presupuesto_web` / `manual` / `importacion` |

`origen` se declara acá, nulo, aunque su uso llegue en otro feature: es el único campo que la spec
nombra explícitamente como parte del ciclo de vida (RF-014), y agregarlo después obliga a una migración
sobre una tabla ya poblada.

Sin `estado_operativo` todavía: no lo pide esta spec. Cuando llegue, es una columna más, no un rediseño.

### `TrabajoItems`

| Columna | Tipo | Nulo | Notas |
|---|---|---|---|
| `id_item` | `INT IDENTITY` | no | PK |
| `id_trabajo` | `INT` | no | FK, `ON DELETE CASCADE` |
| `orden` | `SMALLINT` | no | preserva el orden de carga |
| `detalle` | `NVARCHAR(200)` | sí | puede venir vacío con importe cargado |
| `importe` | `DECIMAL(12,2)` | no | default 0 |

Sin columna `tipo`: la spec (RF-006) dice que no se clasifican. Los campos de seguimiento de repuesto
—pedido, recibido, costo, proveedor— son de otro feature y se agregan acá cuando llegue.

### Índices

- `Vehiculos(patente_norm)` único — es la búsqueda número uno del sistema.
- `Trabajos(numero_presupuesto)` único filtrado sobre no nulos.
- `Trabajos(id_vehiculo, fecha_presupuesto DESC)` — historial de un auto.
- `Trabajos(id_cliente)` — presupuestos de un cliente.
- `TrabajoItems(id_trabajo, orden)` — traer los conceptos en orden.
- `Clientes(nombre_norm)` — búsqueda por parte del nombre.

---

## Vistas

`vw_Presupuestos` — una fila por trabajo, con los totales derivados:

```
id_trabajo, numero_presupuesto, fecha_presupuesto,
cliente (maestro), txt_cliente (impreso), patente_norm, txt_vehiculo,
subtotal_conceptos  = SUM(items.importe)
monto_mano_obra
monto_total         = subtotal_conceptos + monto_mano_obra
cantidad_conceptos, no_concretado, origen, creado_en, modificado_en
```

Responde las preguntas 1, 2, 3, 5, 6 y 7 de la spec. La 4 —último número y próximo— sale de
`MAX(numero_presupuesto)`, pero **no como el próximo a emitir**: RF-020 prohíbe reutilizar y la serie
puede tener huecos, así que la asignación se resuelve en el feature que conecte la herramienta, no acá.

No se crea ninguna vista de color, prioridad ni alerta: principio III, eso lo decide la aplicación.

---

## Importación del CSV

Tres pasos, sin lógica de negocio escondida en un trigger.

1. **Staging.** `stg_PresupuestoCsv` con las catorce columnas como texto, más `linea` y `lote`. Se carga
   crudo, sin convertir ni validar. Un import fallido no deja nada a medias en las tablas reales.
2. **Validación.** Un procedimiento revisa el lote y reporta lo que no pasa —número no entero, importes
   no numéricos, un detalle sin importe— sin escribir en las tablas reales. Lo que falla se informa por
   número de línea, como hace la herramienta.
3. **Consolidación.** Por cada número del lote: se resuelven vehículo y cliente (D5), se hace `MERGE`
   sobre `Trabajos` por `numero_presupuesto`, y los conceptos se reemplazan por completo — se borran los
   del trabajo y se insertan los del archivo, en orden.

**Idempotencia (RF-018).** Reimportar el mismo archivo no crea nada nuevo: el `MERGE` empareja por
número. Un trabajo existente se actualiza sólo si el `modificado_en` del archivo es posterior al
guardado; si es igual o anterior, se saltea. Así un CSV viejo no pisa una corrección más nueva.

**Lo que la importación nunca toca:** `no_concretado` y `origen`. No vienen en el archivo, y sobrescribir
con un valor por defecto lo que alguien cargó en la base sería pérdida silenciosa de datos.

**Los totales del archivo se ignoran.** Se recalculan desde los renglones, igual que hace la herramienta.

**La fila «Mano de obra»** se identifica por la columna `monto_mano_obra` y no por el texto del detalle,
porque un repuesto podría llamarse igual.

---

## Qué se elimina del modelo académico

Aplicando las derogaciones que la constitución ya declaró, en este feature se van:

- `Casos` y su enum de nueve estados, reemplazada por `Trabajos`.
- `CasoItems.tipo`, por RF-006.
- `trg_Casos_ActualizarFecha`: la marca de tiempo la sella quien escribe.
- `sp_CambiarEstadoCaso`: duplicaba la lista de estados del `CHECK`.

`Facturas`, `Cobros`, `Documentos`, `Comunicaciones`, `Peritos` y `CompaniasSeguro` no se tocan en este
feature. Quedan como están hasta que su feature las rediseñe o las elimine.

---

## Verificación contra la constitución

| Principio | Cómo se cumple |
|---|---|
| I — un solo campo de estado | No se crea ninguno. `no_concretado` es un hecho binario, no un ciclo. |
| II — lo derivable no se almacena | Totales en vista. Las columnas `PERSISTED` las mantiene el motor. |
| III — magnitudes, no interpretación | Las vistas devuelven montos y cantidades. Ningún color ni prioridad. |
| IV — el esquema no impide registrar | Todo nulo salvo el nombre del cliente y la patente del vehículo. |
| V — cada hecho en un solo lugar | El snapshot es la excepción justificada de D4. |
| VI — ningún automatismo financiero | Cero triggers. La importación es un procedimiento explícito. |
| VII, VIII — deuda y saldo | No aplican: este feature no toca dinero adeudado. |
| IX — alcance | No se crea ninguna tabla de la lista prohibida. |
| X — la spec precede | Este plan deriva de la spec y no agrega requisitos nuevos. |

---

## Riesgos

- **Clientes duplicados por la importación** (D5). Es aceptado y hay que preverlo como trabajo manual
  posterior. Conviene una consulta que liste nombres parecidos para revisarlos.
- **La numeración sigue viviendo en el navegador** hasta que exista el feature que la conecte. Este plan
  no lo resuelve, y mientras tanto el riesgo de duplicados entre equipos sigue en pie.
- **Reimportar reemplaza los conceptos**, así que sus `id_item` cambian. Nada depende todavía de esos
  ids; cuando el seguimiento de repuestos cuelgue de ellos, esta decisión hay que revisarla.

## Pendiente antes de implementar

Dónde va a correr SQL Server para que la herramienta pueda escribirle. No afecta al esquema —es el mismo
corra donde corra— pero sí a cuándo se puede conectar el presupuesto.
