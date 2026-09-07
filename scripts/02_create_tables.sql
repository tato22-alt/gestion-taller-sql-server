USE GestionTallerDB;
GO

CREATE TABLE Clientes (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    telefono NVARCHAR(30) NOT NULL UNIQUE,
    nombre NVARCHAR(100) NOT NULL,
    email NVARCHAR(120) NULL,
    cuit NVARCHAR(20) NULL,
    creado_en DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE Vehiculos (
    id_vehiculo INT IDENTITY(1,1) PRIMARY KEY,
    patente NVARCHAR(15) NOT NULL UNIQUE,
    marca NVARCHAR(50) NOT NULL,
    modelo NVARCHAR(80) NOT NULL,
    anio INT NULL,
    color NVARCHAR(40) NULL,
    id_cliente INT NOT NULL,
    creado_en DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Vehiculos_Clientes
        FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);
GO

CREATE TABLE CompaniasSeguro (
    id_compania INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    email NVARCHAR(120) NULL,
    telefono NVARCHAR(30) NULL,
    cuit NVARCHAR(20) NULL
);
GO

CREATE TABLE Peritos (
    id_perito INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    email NVARCHAR(120) NULL,
    telefono NVARCHAR(30) NULL,
    id_compania INT NOT NULL,
    CONSTRAINT FK_Peritos_CompaniasSeguro
        FOREIGN KEY (id_compania) REFERENCES CompaniasSeguro(id_compania)
);
GO

CREATE TABLE Casos (
    id_caso INT IDENTITY(1,1) PRIMARY KEY,
    num_presupuesto NVARCHAR(30) NULL,
    id_vehiculo INT NOT NULL,
    id_compania INT NULL,
    id_perito INT NULL,
    num_siniestro NVARCHAR(50) NULL,
    tipo_caso NVARCHAR(30) NOT NULL,
    estado NVARCHAR(30) NOT NULL DEFAULT 'presupuestado',
    descripcion NVARCHAR(500) NULL,
    fecha_ingreso DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    fecha_prometida DATE NULL,
    fecha_entrega DATE NULL,
    creado_en DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    actualizado_en DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Casos_Vehiculos
        FOREIGN KEY (id_vehiculo) REFERENCES Vehiculos(id_vehiculo),

    CONSTRAINT FK_Casos_CompaniasSeguro
        FOREIGN KEY (id_compania) REFERENCES CompaniasSeguro(id_compania),

    CONSTRAINT FK_Casos_Peritos
        FOREIGN KEY (id_perito) REFERENCES Peritos(id_perito),

    CONSTRAINT CK_Casos_TipoCaso
        CHECK (tipo_caso IN ('seguro', 'particular_factura', 'efectivo'))

    -- DEROGADO (constitución v3.0.0, principio I): CK_Casos_Estado, el enum de nueve
    -- estados. Colapsaba tres ejes distintos —operativo, financiero y documental— en una
    -- sola columna, y por eso no se podía consultar ninguno. Un trabajo entregado,
    -- facturado y esperando pago era un estado real del negocio y una imposibilidad del
    -- esquema. Reemplazado por `trabajos` en supabase/migrations/.
);
GO

CREATE TABLE CasoItems (
    id_item INT IDENTITY(1,1) PRIMARY KEY,
    id_caso INT NOT NULL,
    descripcion NVARCHAR(200) NOT NULL,
    -- DEROGADO (T019, RF-006): la columna `tipo`. Los conceptos de un presupuesto no se
    -- clasifican: el detalle lo escribe quien presupuesta.
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal AS (cantidad * precio_unitario) PERSISTED,

    CONSTRAINT FK_CasoItems_Casos
        FOREIGN KEY (id_caso) REFERENCES Casos(id_caso) ON DELETE CASCADE
);
GO

CREATE TABLE Facturas (
    id_factura INT IDENTITY(1,1) PRIMARY KEY,
    num_factura NVARCHAR(30) NOT NULL,
    id_caso INT NOT NULL,
    id_compania INT NULL,
    fecha_emision DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    monto_total DECIMAL(12,2) NOT NULL,
    estado NVARCHAR(30) NOT NULL DEFAULT 'emitida',
    url_pdf NVARCHAR(300) NULL,
    creado_en DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Facturas_Casos
        FOREIGN KEY (id_caso) REFERENCES Casos(id_caso),

    CONSTRAINT FK_Facturas_CompaniasSeguro
        FOREIGN KEY (id_compania) REFERENCES CompaniasSeguro(id_compania),

    -- DEROGADO (constitución v3.0.0, principio VI): el estado `cobrada`. Que una factura
    -- se diga cobrada es un dato derivado —lo dice el saldo, comparando lo facturado con
    -- lo cobrado— y un dato derivado que se almacena es uno que alguien va a olvidar de
    -- actualizar. Se calcula al leer, no se guarda.
    CONSTRAINT CK_Facturas_Estado
        CHECK (estado IN ('emitida', 'enviada', 'anulada'))
);
GO

CREATE TABLE Cobros (
    id_cobro INT IDENTITY(1,1) PRIMARY KEY,
    id_caso INT NOT NULL,
    id_factura INT NULL,
    monto DECIMAL(12,2) NOT NULL,
    tipo_cobro NVARCHAR(30) NOT NULL,
    fecha_cobro DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    nota NVARCHAR(300) NULL,
    creado_en DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Cobros_Casos
        FOREIGN KEY (id_caso) REFERENCES Casos(id_caso),

    CONSTRAINT FK_Cobros_Facturas
        FOREIGN KEY (id_factura) REFERENCES Facturas(id_factura),

    CONSTRAINT CK_Cobros_TipoCobro
        CHECK (tipo_cobro IN ('facturado', 'efectivo'))
);
GO

CREATE TABLE Comunicaciones (
    id_comunicacion INT IDENTITY(1,1) PRIMARY KEY,
    id_caso INT NOT NULL,
    id_perito INT NULL,
    tipo NVARCHAR(30) NOT NULL,
    direccion NVARCHAR(30) NOT NULL,
    asunto NVARCHAR(150) NULL,
    cuerpo NVARCHAR(MAX) NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Comunicaciones_Casos
        FOREIGN KEY (id_caso) REFERENCES Casos(id_caso),

    CONSTRAINT FK_Comunicaciones_Peritos
        FOREIGN KEY (id_perito) REFERENCES Peritos(id_perito),

    CONSTRAINT CK_Comunicaciones_Tipo
        CHECK (tipo IN ('email', 'whatsapp', 'llamada', 'presencial')),

    CONSTRAINT CK_Comunicaciones_Direccion
        CHECK (direccion IN ('entrante', 'saliente'))
);
GO

CREATE TABLE Documentos (
    id_documento INT IDENTITY(1,1) PRIMARY KEY,
    id_caso INT NOT NULL,
    id_factura INT NULL,
    tipo NVARCHAR(40) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    url NVARCHAR(300) NOT NULL,

    CONSTRAINT FK_Documentos_Casos
        FOREIGN KEY (id_caso) REFERENCES Casos(id_caso),

    CONSTRAINT FK_Documentos_Facturas
        FOREIGN KEY (id_factura) REFERENCES Facturas(id_factura),

    CONSTRAINT CK_Documentos_Tipo
        CHECK (tipo IN ('foto_ingreso', 'foto_terminado', 'presupuesto_pdf', 'factura_pdf', 'otro'))
);
GO
