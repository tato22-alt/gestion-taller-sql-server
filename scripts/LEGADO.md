# Estos scripts NO son el modelo actual

Esta carpeta es el **modelo académico en SQL Server** con el que arrancó el repositorio. Ya no
describe la base de El Semáforo.

**El modelo vigente es PostgreSQL sobre Supabase, y vive en `supabase/migrations/`.**
Se documenta en `docs/diccionario-datos.md`.

## Por qué sigue acá

La constitución (v3.0.0) dice que del modelo previo *"se conserva lo que representa correctamente el
negocio y se rediseña lo que no"*, y el plan del feature 001 decidió que `Facturas`, `Cobros`,
`Documentos`, `Comunicaciones`, `Peritos` y `CompaniasSeguro` **quedan como están hasta que su
feature las rediseñe o las elimine**. Se conservan como material de referencia para esos features,
no como algo que se pueda ejecutar.

`Casos` fue reemplazada por `trabajos`. Sigue en el script porque cinco tablas la referencian por
clave foránea, y borrarla dejaría el script roto — no porque siga vigente.

## Qué se retiró, y por qué

Lo que la constitución declaró derogado por violar los principios I y VI, más lo que agregó T019.
Cada corte quedó marcado con un comentario `DEROGADO` en el lugar donde estaba.

| Qué | Dónde estaba | Por qué |
|---|---|---|
| El enum de nueve estados de `Casos` | `02_create_tables.sql` | Principio I. Colapsaba tres ejes —operativo, financiero, documental— en una columna, y por eso no se podía consultar ninguno |
| `CasoItems.tipo` | `02_create_tables.sql` | RF-006. Los conceptos no se clasifican: el detalle lo escribe quien presupuesta |
| El estado `cobrada` de `Facturas` | `02_create_tables.sql` | Principio VI. Que una factura esté cobrada es derivado del saldo; almacenarlo garantiza que alguien lo desactualice |
| `trg_Casos_ActualizarFecha` | `07_triggers.sql`, archivo retirado | Principio VI |
| `trg_Cobros_ActualizarFactura` | `07_triggers.sql`, archivo retirado | Principio VI. Marcaba facturas como cobradas solo |
| `sp_CambiarEstadoCaso` | `06_stored_procedures.sql` | T019. Duplicaba la lista de estados del CHECK: dos definiciones del mismo dominio |
| El `UPDATE` de estado dentro de `sp_RegistrarCobro` | `06_stored_procedures.sql` | Principio VI. **Marcaba el caso como cobrado ante cualquier cobro sin factura, sin comparar montos: una seña cerraba un trabajo entero.** Es el caso que la constitución cita para prohibir que un automatismo escriba estados financieros |

## Lo que quedó pendiente de decisión

Si esta carpeta debe existir siquiera, o si conviene borrarla entera y dejar que cada feature futuro
rediseñe lo suyo desde la spec. No se resolvió acá porque el plan del 001 dijo explícitamente que
esas tablas no se tocan en este feature.
