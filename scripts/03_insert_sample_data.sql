USE GestionTallerDB;
GO

INSERT INTO Clientes (telefono, nombre, email, cuit)
VALUES
('2255000001', 'Cliente Demo 1', 'cliente1@example.com', '20-00000001-1'),
('2255000002', 'Cliente Demo 2', 'cliente2@example.com', NULL),
('2255000003', 'Cliente Demo 3', NULL, NULL);
GO

INSERT INTO Vehiculos (patente, marca, modelo, anio, color, id_cliente)
VALUES
('AA123BB', 'Toyota', 'Corolla', 2018, 'Gris', 1),
('AB456CD', 'Ford', 'Ranger', 2020, 'Blanco', 2),
('AC789EF', 'Volkswagen', 'Gol', 2016, 'Rojo', 3);
GO

INSERT INTO CompaniasSeguro (nombre, email, telefono, cuit)
VALUES
('Seguro Demo A', 'siniestros@segurodemoa.com', '0800-111-111', '30-00000001-1'),
('Seguro Demo B', 'peritos@segurodemob.com', '0800-222-222', '30-00000002-2');
GO

INSERT INTO Peritos (nombre, email, telefono, id_compania)
VALUES
('Perito Demo 1', 'perito1@example.com', '2255000101', 1),
('Perito Demo 2', 'perito2@example.com', '2255000102', 2);
GO

INSERT INTO Casos (num_presupuesto, id_vehiculo, id_compania, id_perito, num_siniestro, tipo_caso, estado, descripcion, fecha_ingreso, fecha_prometida)
VALUES
('P-0001', 1, 1, 1, 'SIN-1001', 'seguro', 'aprobado', 'Reparación lateral derecho y pintura.', '2026-05-01', '2026-05-15'),
('P-0002', 2, NULL, NULL, NULL, 'particular_factura', 'en_taller', 'Reparación paragolpes delantero.', '2026-05-03', '2026-05-12'),
('P-0003', 3, NULL, NULL, NULL, 'efectivo', 'terminado', 'Pulido y reparación menor.', '2026-05-05', '2026-05-08');
GO

INSERT INTO CasoItems (id_caso, descripcion, tipo, cantidad, precio_unitario)
VALUES
(1, 'Mano de obra chapa lateral', 'mano_obra', 1, 180000),
(1, 'Materiales de pintura', 'pintura', 1, 70000),
(2, 'Reparación paragolpes', 'mano_obra', 1, 90000),
(2, 'Repuesto paragolpes', 'repuesto', 1, 160000),
(3, 'Pulido general', 'mano_obra', 1, 60000);
GO

INSERT INTO Facturas (num_factura, id_caso, id_compania, fecha_emision, monto_total, estado)
VALUES
('F-0001', 1, 1, '2026-05-16', 250000, 'emitida'),
('F-0002', 2, NULL, '2026-05-13', 250000, 'enviada');
GO

INSERT INTO Cobros (id_caso, id_factura, monto, tipo_cobro, fecha_cobro, nota)
VALUES
(3, NULL, 60000, 'efectivo', '2026-05-08', 'Cobro en efectivo registrado como ingreso operativo.');
GO

INSERT INTO Comunicaciones (id_caso, id_perito, tipo, direccion, asunto, cuerpo)
VALUES
(1, 1, 'email', 'saliente', 'Envío de presupuesto', 'Se envía presupuesto para revisión.'),
(1, 1, 'email', 'entrante', 'Presupuesto aprobado', 'La compañía aprueba el presupuesto.');
GO

INSERT INTO Documentos (id_caso, id_factura, tipo, nombre, url)
VALUES
(1, NULL, 'presupuesto_pdf', 'presupuesto_p0001.pdf', 'https://example.com/presupuesto_p0001.pdf'),
(1, 1, 'factura_pdf', 'factura_f0001.pdf', 'https://example.com/factura_f0001.pdf');
GO
