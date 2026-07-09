USE GestionTallerDB;
GO

CREATE OR ALTER PROCEDURE sp_CambiarEstadoCaso
    @id_caso INT,
    @nuevo_estado NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    IF @nuevo_estado NOT IN ('presupuestado', 'enviado', 'aprobado', 'en_taller', 'en_trabajo', 'terminado', 'entregado', 'facturado', 'cobrado')
    BEGIN
        RAISERROR('Estado de caso inválido.', 16, 1);
        RETURN;
    END;

    UPDATE Casos
    SET estado = @nuevo_estado,
        actualizado_en = SYSDATETIME()
    WHERE id_caso = @id_caso;
END;
GO

CREATE OR ALTER PROCEDURE sp_RegistrarCobro
    @id_caso INT,
    @id_factura INT = NULL,
    @monto DECIMAL(12,2),
    @tipo_cobro NVARCHAR(30),
    @fecha_cobro DATE = NULL,
    @nota NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @tipo_cobro NOT IN ('facturado', 'efectivo')
    BEGIN
        RAISERROR('Tipo de cobro inválido.', 16, 1);
        RETURN;
    END;

    INSERT INTO Cobros (id_caso, id_factura, monto, tipo_cobro, fecha_cobro, nota)
    VALUES (@id_caso, @id_factura, @monto, @tipo_cobro, ISNULL(@fecha_cobro, CAST(GETDATE() AS DATE)), @nota);

    UPDATE Casos
    SET estado = 'cobrado',
        actualizado_en = SYSDATETIME()
    WHERE id_caso = @id_caso
      AND @id_factura IS NULL;
END;
GO

CREATE OR ALTER PROCEDURE sp_ObtenerResumenCaso
    @id_caso INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM vw_CasosResumen
    WHERE id_caso = @id_caso;

    SELECT
        descripcion,
        tipo,
        cantidad,
        precio_unitario,
        subtotal
    FROM CasoItems
    WHERE id_caso = @id_caso;
END;
GO
