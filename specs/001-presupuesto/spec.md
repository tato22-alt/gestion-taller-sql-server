# Spec 001 — Presupuesto

**Estado:** borrador, pendiente de aprobación
**Rama:** `claude/semaforo-taller-system-eroppo`
**Constitución aplicable:** v2.0.0

---

## Por qué

El presupuesto es el nacimiento de todo trabajo del taller. Hoy su único respaldo estable es el
duplicado del talonario, y cuando el talonario se pierde se pierde el precio acordado.

Existe además un presupuesto digital en uso (`presupuesto.html`) que ya genera el documento, numera
desde el 16001 continuando el talonario, y guarda el historial en el navegador. Ese historial vive en el
`localStorage` de una máquina: se pierde al limpiar el navegador o al cambiar de equipo.

Esta spec define qué información sobre presupuestos tiene que poder registrar y responder la base, para
que el presupuesto deje de depender del papel y del navegador.

## Alcance

**Entra:** el presupuesto y las entidades mínimas que lo sostienen — cliente, vehículo, trabajo y los
conceptos presupuestados. La importación del histórico ya cargado.

**No entra, y son features posteriores:** deuda y cobranza, facturación, documentos adjuntos, datos de
seguro y siniestro, seguimiento de repuestos (pedido/recibido/costo), estado operativo del trabajo.

---

## Escenarios

**E1 — Auto que nunca vino.** Llega un auto desconocido, se presupuesta. Hay que poder registrar el
cliente, el vehículo y el presupuesto en un solo acto, sin que nada de eso exija datos que no se tienen.

**E2 — Auto que ya vino.** Llega un auto que estuvo antes. Su patente ya existe en la base. El
presupuesto nuevo tiene que poder apoyarse en el vehículo existente, y el cliente puede ser otro — los
autos se venden, y no siempre lo trae el titular.

**E3 — Presupuesto que no se concreta.** Se presupuesta y el cliente no vuelve. El registro tiene que
quedar consultable sin ensuciar los listados de trabajo activo, y sin obligar a inventar fechas ni
estados de un trabajo que nunca ocurrió.

**E4 — Dos presupuestos al mismo auto.** El mismo vehículo se presupuesta dos veces en fechas distintas,
por daños distintos. Son dos trabajos independientes con dos números.

**E5 — Corrección de un presupuesto.** Se equivocó un importe y se corrige el mismo día, antes de
entregárselo al cliente. Conserva su número.

**E6 — Histórico existente.** Los presupuestos ya cargados en el navegador tienen que poder incorporarse
a la base sin volver a tipearlos.

---

## Requisitos

### Identidad y numeración

- **RF-001** — Cada presupuesto tiene un número único, correlativo, que continúa la numeración del
  talonario físico. El primero de la serie digital es el **16001**.
- **RF-002** — Ese número es el identificador del trabajo en todo el sistema. No existe una segunda
  numeración paralela: el número que se dicta por teléfono es el mismo que se busca en la base.
- **RF-003** — Presupuestar crea el trabajo. No hay un paso posterior de conversión ni una entidad
  separada que después haya que vincular.

### Contenido del presupuesto

- **RF-004** — Un presupuesto registra: fecha, cliente, dirección, teléfono, vehículo, patente, una lista
  de conceptos con importe, y un monto de mano de obra.
- **RF-005** — La mano de obra es un monto único del presupuesto, no una línea de la lista. Es como
  presupuesta el taller.
- **RF-006** — Cada concepto de la lista tiene un detalle en texto libre y un importe. No se clasifica
  por tipo: el detalle lo escribe quien presupuesta.
- **RF-007** — El total es la suma de los conceptos más la mano de obra. Es el total final que paga el
  cliente; no se le suma nada después.
- **RF-008** — Todos los campos descriptivos pueden faltar. Un presupuesto con sólo importes es
  registrable, igual que hoy en el talonario.

### Cliente y vehículo

- **RF-009** — La base guarda cliente y vehículo como entidades propias, para poder responder por
  patente y por cliente, y para no volver a pedir lo que ya está.
- **RF-010** — El presupuesto conserva además **el texto tal como se imprimió**: nombre, dirección,
  teléfono y descripción del vehículo. Si mañana se corrige el nombre del cliente en su ficha, el
  presupuesto ya emitido sigue diciendo lo que decía el papel.
- **RF-011** — El vehículo se identifica por patente, normalizada en mayúsculas y sin separadores, y se
  describe en un campo de texto libre. No se separan marca, modelo, año ni color: ninguna decisión del
  taller depende de tenerlos aparte.
- **RF-012** — Un vehículo puede tener presupuestos de clientes distintos a lo largo del tiempo. El
  cliente del presupuesto es el de ese presupuesto; el vehículo recuerda el último conocido sólo para
  poder proponerlo.
- **RF-013** — Registrar un cliente no exige teléfono, dirección ni ningún otro dato fuera del nombre.

### Ciclo de vida

- **RF-014** — Un trabajo nace del presupuesto sin origen definido. No siempre se sabe en el momento si
  va a ir por seguro o como particular; el esquema no puede exigirlo al crear.
- **RF-015** — Un presupuesto que no se concreta se marca como tal y deja de aparecer en lo activo, sin
  perder consultabilidad.
- **RF-016** — Un presupuesto se puede corregir conservando su número. **Decisión consciente:** no se
  versiona el histórico de correcciones — el presupuesto vigente es el que está. Se acepta el riesgo de
  perder la traza de un importe corregido, a cambio de no agregar una tabla que nadie va a consultar.

### Migración

- **RF-017** — Los presupuestos exportados por la herramienta actual tienen que poder importarse. El
  formato es el CSV que ya genera, con una fila por concepto y las columnas: `numero_presupuesto`,
  `fecha_consulta`, `nombre_cliente`, `direccion`, `telefono`, `vehiculo`, `patente`, `detalle`,
  `importe`, `subtotal_repuestos`, `monto_mano_obra`, `monto_total`.
- **RF-018** — La importación tiene que ser repetible sin duplicar: reimportar el mismo archivo no crea
  presupuestos nuevos.
- **RF-019** — Los datos importados pueden venir incompletos o inconsistentes — patentes mal escritas,
  clientes sin teléfono, el mismo cliente con el nombre escrito de dos maneras. La importación los acepta
  igual; no es tarea de la migración limpiar el pasado.

---

## Preguntas que la base tiene que poder responder

Esto es lo verificable de la spec. Al terminar el feature, cada una tiene que tener respuesta en una
sola consulta:

1. ¿Qué presupuesto tiene el número 16043?
2. ¿Qué presupuestos existen para la patente AA123BB, del más nuevo al más viejo?
3. ¿Qué presupuestos tiene un cliente, buscándolo por parte de su nombre?
4. ¿Cuál fue el último presupuesto cargado y cuál es el próximo número?
5. ¿Cuánto suma un presupuesto, y qué conceptos lo componen?
6. ¿Qué presupuestos quedaron sin concretarse?
7. ¿Cuántos presupuestos se hicieron en un mes y por qué monto total?

---

## Entidades

Descriptivas, sin tipos ni sintaxis — eso es el plan.

**Cliente** — nombre; teléfono, dirección, email y CUIT opcionales. Nada más obligatorio que el nombre.

**Vehículo** — patente normalizada, única; descripción en texto libre; último cliente conocido, opcional.

**Trabajo** — el expediente, identificado por el número de presupuesto. Fecha, cliente, vehículo, el
snapshot de lo impreso, el monto de mano de obra, el total, y la marca de no concretado. El origen queda
indefinido hasta que se sepa.

**Concepto presupuestado** — detalle e importe, colgando del trabajo, en el orden en que se cargaron.

---

## Fuera de alcance

Deuda, deudor, factura, cobro y retenciones. Documentos y fotos. Compañía, siniestro, inspección y
resolución. Estado operativo, turno, ingreso y entrega. Pedido, recepción y costo real de repuestos.
Usuarios y permisos.

---

## Pendientes de aclaración

- **[ACLARAR]** ¿Desde qué número arrancan los presupuestos reales ya cargados? El código dice 16001,
  pero hay que confirmar cuántos hay efectivamente cargados y desde cuándo.
- **[ACLARAR]** ¿Puede un presupuesto cubrir dos vehículos del mismo cliente? Se asume que no: un
  presupuesto, un auto.
- **[ACLARAR]** Cuando el trabajo se hace, ¿el total facturado es siempre el del presupuesto, o se ajusta
  con frecuencia? No afecta a esta spec, pero define cómo nace la deuda en el feature siguiente.

---

## Criterios de aceptación

1. Se puede registrar el presupuesto de un auto y un cliente que nunca estuvieron, en un solo acto.
2. Se puede registrar un presupuesto con importes y sin ningún dato del cliente.
3. Un segundo presupuesto sobre la misma patente reutiliza el vehículo y no lo duplica.
4. Corregir el nombre de un cliente no altera lo que dice un presupuesto ya emitido.
5. Las siete preguntas de arriba se responden cada una con una sola consulta.
6. El CSV de la herramienta actual se importa completo, y reimportarlo no duplica nada.
7. Ningún dato del seguro, de la deuda ni del estado operativo es necesario para que todo lo anterior
   funcione.
