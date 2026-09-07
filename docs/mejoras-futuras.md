# Qué sigue, y qué no

Este documento reemplaza a una lista de deseos que venía del modelo académico y que proponía varias
cosas que la constitución v3.0.0 prohíbe expresamente. Se reescribió porque una hoja de ruta que
contradice los principios es peor que no tener ninguna: alguien la lee y construye lo que se decidió
no construir.

---

## Lo próximo, en orden

**1. Conectar la página del presupuesto a la base.** Es lo único que hace falta para que el sistema
empiece a servir. Falta:

- Login en la página, que hoy no tiene ninguno.
- Confirmar que los usuarios de Supabase Auth están dados de alta (`select * from auth.users`).
- Que la página pida el número con `fn_proximo_numero_presupuesto()` en vez de repartirlo desde el
  navegador. La base ya está lista para eso.

Es urgente por una razón concreta: cada presupuesto que se cargue en el navegador sin conectar es uno
que después habrá que mover a mano.

**2. Deuda y cobranza.** Es la dolencia número uno del negocio y el motivo del proyecto. Necesita su
propia spec: deudor explícito (principio VII), saldo derivado y nunca almacenado (principio II), y
retenciones imputadas a la deuda para que el saldo pueda llegar a cero (principio VIII).

**3. Estado operativo del trabajo.** Dónde está el auto. Es el **único** campo de estado que el
modelo admite (principio I), y hoy no existe: cuando llegue es una columna más en `trabajos`, no un
rediseño.

**4. Facturación, documentos, seguro y siniestro.** Cada uno con su spec, cuando el negocio lo pida.

---

## Lo que está en pausa

**La importación del histórico** (bloque D del feature 001). Escrita y sin empezar: no hay registro
histórico que importar, el taller está pasando de papel a digital. Vuelve a tener sentido sólo si se
cargan presupuestos en el navegador antes de conectar la página.

---

## Lo que NO se va a construir

No es una lista de pendientes: es lo que la constitución (principio IX) sacó del alcance a propósito.
Entra sólo con una enmienda escrita que nombre la dolencia que resuelve.

| No entra | Por qué |
|---|---|
| Cuenta corriente y pagos a proveedores | Fuera de alcance por el principio IX |
| Conciliación bancaria | Ídem |
| Stock e inventario | Ídem |
| RRHH y productividad | Ídem |
| Planificación de capacidad | Ídem |
| Portal de clientes | Ídem |
| Sub-etapas de la reparación (chapa, pintura, pulido, lavado) | Ídem |
| Asignación de tareas por operario | Ídem |
| Registro manual de comunicaciones | Ídem |
| Historial de correcciones de un presupuesto | RF-016 lo decidió explícitamente: el presupuesto vigente es el que está. Se acepta perder la traza de un importe corregido a cambio de no agregar una tabla que nadie va a consultar |
| Cualquier columna de estado financiero, documental o de siniestro | Principio I. La respuesta correcta es una vista, no una columna |
| Cualquier dato derivable almacenado | Principio II. Un dato derivado que se almacena es uno que alguien va a olvidar de actualizar |

El taller ya funciona. Su problema es administrativo. Cada tabla que modela la operación agrega carga
de datos sin resolver ninguna de las dolencias críticas.

---

## Lo que decide la aplicación, no esta base

Está acá para que no se pida por error en una spec de datos:

- El color del semáforo, la prioridad de una lista, el texto de un aviso.
- Qué campos exige al cargar. La base reporta qué falta con `vw_presupuestos_incompletos`, pero no
  bloquea: un sistema que impide registrar la realidad se saltea.
- La atomicidad de "un solo acto" al crear cliente + vehículo + presupuesto. Son llamadas REST
  separadas y agruparlas es orquestación, que la constitución pone fuera de este repositorio.
