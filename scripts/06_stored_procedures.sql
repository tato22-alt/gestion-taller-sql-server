USE GestionTallerDB;
GO

-- DEROGADO (T019): sp_CambiarEstadoCaso. Duplicaba la lista de estados que ya estaba en
-- el CHECK de la tabla, así que había dos definiciones del mismo dominio y ninguna
-- mandaba sobre la otra. El estado operativo se escribe directo; no hace falta un
-- procedimiento para eso.

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

    -- DEROGADO (constitución v3.0.0, principio VI): acá iba un
    --     UPDATE Casos SET estado = 'cobrado' ... WHERE @id_factura IS NULL
    -- que marcaba el caso como cobrado ante CUALQUIER cobro sin factura, sin comparar
    -- montos: una seña cerraba un trabajo entero. Es el ejemplo que la constitución cita
    -- para prohibir que un automatismo escriba estados financieros. Sólo un cobro
    -- registrado baja un saldo, y el saldo se lee de una vista.
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
