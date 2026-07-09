USE GestionTallerDB;
GO

-- 1. Casos con cliente y vehículo
SELECT
    c.id_caso,
    c.num_presupuesto,
    cli.nombre AS cliente,
    v.patente,
    v.marca,
    v.modelo,
    c.tipo_caso,
    c.estado,
    c.fecha_ingreso
FROM Casos c
INNER JOIN Vehiculos v ON c.id_vehiculo = v.id_vehiculo
INNER JOIN Clientes cli ON v.id_cliente = cli.id_cliente
ORDER BY c.fecha_ingreso DESC;
GO

-- 2. Total presupuestado por caso
SELECT
    c.id_caso,
    c.num_presupuesto,
    SUM(ci.subtotal) AS total_presupuestado
FROM Casos c
INNER JOIN CasoItems ci ON c.id_caso = ci.id_caso
GROUP BY c.id_caso, c.num_presupuesto
ORDER BY total_presupuestado DESC;
GO

-- 3. Facturas pendientes de cobro
SELECT
    f.id_factura,
    f.num_factura,
    f.monto_total,
    f.estado,
    c.num_presupuesto,
    cs.nombre AS compania
FROM Facturas f
INNER JOIN Casos c ON f.id_caso = c.id_caso
LEFT JOIN CompaniasSeguro cs ON f.id_compania = cs.id_compania
WHERE f.estado <> 'cobrada'
ORDER BY f.fecha_emision DESC;
GO

-- 4. Ingresos por mes
SELECT
    YEAR(fecha_cobro) AS anio,
    MONTH(fecha_cobro) AS mes,
    SUM(monto) AS total_cobrado
FROM Cobros
GROUP BY YEAR(fecha_cobro), MONTH(fecha_cobro)
ORDER BY anio DESC, mes DESC;
GO

-- 5. Casos por estado
SELECT
    estado,
    COUNT(*) AS cantidad
FROM Casos
GROUP BY estado
ORDER BY cantidad DESC;
GO

-- 6. Casos de seguro con perito y compañía
SELECT
    c.id_caso,
    c.num_siniestro,
    c.estado,
    cs.nombre AS compania,
    p.nombre AS perito,
    p.email AS email_perito
FROM Casos c
LEFT JOIN CompaniasSeguro cs ON c.id_compania = cs.id_compania
LEFT JOIN Peritos p ON c.id_perito = p.id_perito
WHERE c.tipo_caso = 'seguro';
GO
