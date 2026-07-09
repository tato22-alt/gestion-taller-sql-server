USE GestionTallerDB;
GO

CREATE OR ALTER VIEW vw_CasosResumen AS
SELECT
    c.id_caso,
    c.num_presupuesto,
    cli.nombre AS cliente,
    cli.telefono,
    v.patente,
    v.marca,
    v.modelo,
    c.tipo_caso,
    c.estado,
    c.fecha_ingreso,
    c.fecha_prometida,
    SUM(ISNULL(ci.subtotal, 0)) AS total_presupuestado
FROM Casos c
INNER JOIN Vehiculos v ON c.id_vehiculo = v.id_vehiculo
INNER JOIN Clientes cli ON v.id_cliente = cli.id_cliente
LEFT JOIN CasoItems ci ON c.id_caso = ci.id_caso
GROUP BY
    c.id_caso,
    c.num_presupuesto,
    cli.nombre,
    cli.telefono,
    v.patente,
    v.marca,
    v.modelo,
    c.tipo_caso,
    c.estado,
    c.fecha_ingreso,
    c.fecha_prometida;
GO

CREATE OR ALTER VIEW vw_FacturasPendientes AS
SELECT
    f.id_factura,
    f.num_factura,
    f.fecha_emision,
    f.monto_total,
    f.estado,
    c.id_caso,
    c.num_presupuesto,
    cs.nombre AS compania
FROM Facturas f
INNER JOIN Casos c ON f.id_caso = c.id_caso
LEFT JOIN CompaniasSeguro cs ON f.id_compania = cs.id_compania
WHERE f.estado IN ('emitida', 'enviada');
GO

CREATE OR ALTER VIEW vw_CobrosMensuales AS
SELECT
    YEAR(fecha_cobro) AS anio,
    MONTH(fecha_cobro) AS mes,
    tipo_cobro,
    SUM(monto) AS total_cobrado,
    COUNT(*) AS cantidad_cobros
FROM Cobros
GROUP BY YEAR(fecha_cobro), MONTH(fecha_cobro), tipo_cobro;
GO
