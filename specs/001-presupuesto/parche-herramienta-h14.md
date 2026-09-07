# Parche para la herramienta de presupuesto — H14

**Para:** el repositorio de la página (`tato22-alt/semaforo-presupuesto`), no este.
**Por qué:** decidido por Luciano al resolver H14 — arreglar la herramienta antes de exportar es
la única opción que recupera los presupuestos que hoy desaparecen del CSV.
**Cuándo:** antes de exportar el histórico. Después ya no sirve para lo perdido.

---

## El problema

`exportarCSV` emite una fila por renglón, y una extra de mano de obra sólo si el monto no es
cero. Un presupuesto sin renglones y con mano de obra en cero **no emite ninguna fila**. Y
guardarlo está permitido: `guardarYPdf` sólo exige cliente **o** renglones.

Verificado ejecutando la función real: un presupuesto con cliente y sin importes desaparece.

## El cambio

En `exportarCSV`, dentro del `guardados.forEach`. Antes:

```js
    const agregar = (detalle, importe) => filas.push([...izq, detalle, importe, ...der].map(celda).join(';'));
    p.items.forEach(i => agregar(i.detalle, i.importe));
    if(p.monto_mano_obra) agregar('Mano de obra', p.monto_mano_obra);
```

Después:

```js
    const agregar = (detalle, importe) => filas.push([...izq, detalle, importe, ...der].map(celda).join(';'));
    let emitidas = 0;
    p.items.forEach(i => { agregar(i.detalle, i.importe); emitidas++; });
    if(p.monto_mano_obra){ agregar('Mano de obra', p.monto_mano_obra); emitidas++; }
    if(!emitidas) agregar('', '');   // ningún presupuesto se pierde: siempre al menos una fila
```

Son tres líneas. No cambia nada de lo que ya se exportaba: sólo agrega una fila con detalle e
importe vacíos para los presupuestos que hoy no emiten ninguna.

## Cómo lo lee la importación

La fila vacía no crea un concepto fantasma. La regla de lectura descarta los renglones sin
detalle y sin importe — que es exactamente lo que hace la propia herramienta al leer el
formulario (`.filter(i => i.detalle || i.importe)`).

## Verificado

Con la lógica real, sobre cinco casos:

| Caso | Antes | Después |
|---|---|---|
| Renglones + mano de obra | 3 filas | 3 filas, igual |
| Sólo mano de obra, sin renglones | 1 fila | 1 fila, igual |
| **Cliente sin ningún importe** | **0 filas — se perdía** | **1 fila** |
| Repuesto llamado "Mano de obra" por el mismo monto | 2 filas idénticas | 2 filas idénticas, igual |
| Renglón con detalle y sin importe | 2 filas | 2 filas, igual |

Los cinco se reconstruyen correctamente al importar.
