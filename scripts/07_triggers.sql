USE GestionTallerDB;
GO

CREATE OR ALTER TRIGGER trg_Casos_ActualizarFecha
ON Casos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET actualizado_en = SYSDATETIME()
    FROM Casos c
    INNER JOIN inserted i ON c.id_caso = i.id_caso;
END;
GO

CREATE OR ALTER TRIGGER trg_Cobros_ActualizarFactura
ON Cobros
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE f
    SET estado = 'cobrada'
    FROM Facturas f
    INNER JOIN (
        SELECT
            c.id_factura,
            SUM(c.monto) AS total_cobrado
        FROM Cobros c
        WHERE c.id_factura IS NOT NULL
        GROUP BY c.id_factura
    ) cobros ON f.id_factura = cobros.id_factura
    WHERE cobros.total_cobrado >= f.monto_total;
END;
GO
