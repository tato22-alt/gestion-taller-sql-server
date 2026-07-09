# Diccionario de datos

## Clientes

Representa a la persona dueña o responsable del vehículo.

Campos principales:

- `id_cliente`: identificador interno.
- `telefono`: teléfono único del cliente.
- `nombre`: nombre del cliente.
- `email`: correo opcional.
- `cuit`: CUIT opcional.
- `creado_en`: fecha de alta.

## Vehiculos

Representa un auto asociado a un cliente.

Campos principales:

- `id_vehiculo`: identificador interno.
- `patente`: patente única.
- `marca`, `modelo`, `anio`, `color`: datos del vehículo.
- `id_cliente`: relación con el cliente.

## CompaniasSeguro

Representa compañías de seguro que pueden pagar reparaciones.

## Peritos

Representa contactos/peritos asociados a una compañía de seguro.

## Casos

Entidad central del sistema. Un caso representa un trabajo real sobre un vehículo.

Campos principales:

- `id_caso`: identificador interno.
- `num_presupuesto`: número de presupuesto.
- `id_vehiculo`: vehículo asociado.
- `id_compania`: compañía de seguro, cuando aplica.
- `id_perito`: perito asociado, cuando aplica.
- `num_siniestro`: número de siniestro, cuando aplica.
- `tipo_caso`: `seguro`, `particular_factura` o `efectivo`.
- `estado`: flujo operativo del caso.
- `descripcion`: detalle general.
- `fecha_ingreso`, `fecha_prometida`, `fecha_entrega`: fechas operativas.

## CasoItems

Líneas del presupuesto o trabajo realizado.

Tipos posibles:

- `mano_obra`
- `repuesto`
- `material`
- `pintura`
- `sublet`
- `otro`

## Facturas

Documento fiscal asociado a un caso.

Estados posibles:

- `emitida`
- `enviada`
- `cobrada`
- `anulada`

## Cobros

Movimiento real de dinero asociado a un caso y opcionalmente a una factura.

Tipos posibles:

- `facturado`
- `efectivo`

## Comunicaciones

Registro de contactos con clientes, peritos o aseguradoras.

## Documentos

Fotos, presupuestos, facturas o documentos asociados a un caso.
