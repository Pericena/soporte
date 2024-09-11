USE MASTER;
GO

BEGIN TRY
    -- Verificar si la base de datos existe
    IF DB_ID('AirlineDB') IS NOT NULL
    BEGIN
        -- Establecer la base de datos en modo de usuario único y cerrar todas las conexiones activas
        ALTER DATABASE AirlineDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        PRINT 'Conexiones activas cerradas y base de datos en modo de usuario único.';

        -- Intentar eliminar la base de datos
        DROP DATABASE AirlineDB;
        PRINT 'Base de datos AirlineDB eliminada.';
    END
    ELSE
    BEGIN
        PRINT 'La base de datos AirlineDB no existe, no es necesario eliminarla.';
    END
END TRY
BEGIN CATCH
    -- Capturar errores y proporcionar mensajes adecuados
    IF ERROR_NUMBER() = 3702
    BEGIN
        PRINT 'No se puede quitar la base de datos ''AirlineDB''; está en uso.';
    END
    ELSE
    BEGIN
        PRINT 'Error al intentar eliminar la base de datos: ' + ERROR_MESSAGE();
    END
END CATCH
GO

-- Crear la base de datos si no existe
IF DB_ID('AirlineDB') IS NULL
BEGIN
    CREATE DATABASE AirlineDB;
    PRINT 'Base de datos AirlineDB creada.';
END
GO


-- Usar la base de datos recién creada
USE AirlineDB;
GO

-------------------- CREACIÓN DE TABLAS --------------------

-- Creación de la tabla Country 
IF OBJECT_ID('Country', 'U') IS NULL 
BEGIN
  CREATE TABLE Country (
    IdCountry INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria con autoincremento
    NameC NVARCHAR(255) NOT NULL,  -- Nombre del país no nulo
    CONSTRAINT UQ_Country_NameC UNIQUE(NameC)  -- Restricción de unicidad
  );
  PRINT 'Tabla Country creada.';
  
  -- Crear un índice no agrupado en NameC para mejorar el rendimiento de consultas
  CREATE NONCLUSTERED INDEX IX_Country_NameC ON Country(NameC);
  PRINT 'Índice no agrupado en NameC creado.';
END
GO

-- Reglas adicionales para asegurar la integridad
ALTER TABLE Country
ADD CONSTRAINT CK_Country_NameC_Length CHECK (LEN(NameC) >= 3);  -- El nombre del país debe tener al menos 3 caracteres
GO

-- Creación de la tabla City 
IF OBJECT_ID('City', 'U') IS NULL 
BEGIN
  CREATE TABLE City (
    IdCity INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria con autoincremento
    Name NVARCHAR(255) NOT NULL,  -- Nombre de la ciudad no nulo
    IdCountry INT NOT NULL,  -- Clave foránea hacia Country
    CONSTRAINT FK_City_Country FOREIGN KEY (IdCountry) REFERENCES Country(IdCountry) ON DELETE CASCADE,  -- Relación con Country
    CONSTRAINT UQ_City_Name UNIQUE (Name)  -- Nombre de la ciudad único
  );
  PRINT 'Tabla City creada.';
  
  -- Crear un índice no agrupado en Name para mejorar el rendimiento de consultas
  CREATE NONCLUSTERED INDEX IX_City_Name ON City(Name);
  PRINT 'Índice no agrupado en Name creado.';

  -- Crear un índice no agrupado en IdCountry para optimizar las búsquedas por país
  CREATE NONCLUSTERED INDEX IX_City_IdCountry ON City(IdCountry);
  PRINT 'Índice no agrupado en IdCountry creado.';
END
GO

-- Reglas adicionales para asegurar la integridad
ALTER TABLE City
ADD CONSTRAINT CK_City_Name_Length CHECK (LEN(Name) >= 2);  -- El nombre de la ciudad debe tener al menos 2 caracteres
GO


-- Creacion del indice en IdCountry para mejorar consultas
CREATE INDEX IDX_City_IdCountry ON City(IdCountry);
GO

-- Creación de la tabla Airport con atributos adicionales
IF OBJECT_ID('Airport', 'U') IS NULL 
BEGIN
  CREATE TABLE Airport (
    IdAirport INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria con autoincremento
    Name NVARCHAR(255) NOT NULL,  -- Nombre del aeropuerto no nulo
    IdCity INT NULL,  -- Clave foránea hacia City, puede ser NULL
    Latitude DECIMAL(9, 6) NOT NULL,  -- Latitud del aeropuerto
    Longitude DECIMAL(9, 6) NOT NULL,  -- Longitud del aeropuerto
    IATACode NVARCHAR(3) NOT NULL,  -- Código IATA del aeropuerto
    ICAOCode NVARCHAR(4) NULL,  -- Código ICAO del aeropuerto (opcional)
    RunwayCount INT NULL,  -- Número de pistas en el aeropuerto
    TerminalCount INT NULL,  -- Número de terminales en el aeropuerto
    PassengerTraffic BIGINT NULL,  -- Tráfico de pasajeros anual
    CargoTraffic DECIMAL(10, 2) NULL,  -- Tráfico de carga anual en toneladas
    IsInternational BIT NOT NULL DEFAULT 0,  -- Indica si el aeropuerto es internacional (1: sí, 0: no)
    OpenedDate DATE NULL,  -- Fecha de apertura del aeropuerto
    Description NVARCHAR(255) NULL,  -- Descripción opcional
    FOREIGN KEY (IdCity) REFERENCES City(IdCity) ON DELETE SET NULL,  -- Relación con City
    CONSTRAINT UQ_Airport_Location UNIQUE (Latitude, Longitude),  -- Coordenadas únicas para evitar duplicados
    CONSTRAINT UQ_Airport_Name UNIQUE (Name),  -- Nombre del aeropuerto único
    CONSTRAINT UQ_Airport_IATACode UNIQUE (IATACode),  -- Código IATA único
    CONSTRAINT UQ_Airport_ICAOCode UNIQUE (ICAOCode)  -- Código ICAO único (opcional)
  );
  PRINT 'Tabla Airport creada.';
  
  -- Crear un índice no agrupado en Name para mejorar el rendimiento de consultas
  CREATE NONCLUSTERED INDEX IX_Airport_Name ON Airport(Name);
  PRINT 'Índice no agrupado en Name creado.';

  -- Crear un índice no agrupado en Latitude y Longitude para optimizar las consultas geográficas
  CREATE NONCLUSTERED INDEX IX_Airport_LatLng ON Airport(Latitude, Longitude);
  PRINT 'Índice no agrupado en Latitude y Longitude creado.';
END
GO

-- Reglas adicionales para asegurar la integridad de los datos
ALTER TABLE Airport
ADD CONSTRAINT CK_Airport_Name_Length CHECK (LEN(Name) >= 3);  -- El nombre del aeropuerto debe tener al menos 3 caracteres
GO

-- Asegurar que el código IATA tenga exactamente 3 caracteres
ALTER TABLE Airport
ADD CONSTRAINT CK_Airport_IATACode_Length CHECK (LEN(IATACode) = 3);
GO

-- Asegurar que el código ICAO tenga exactamente 4 caracteres si se proporciona
ALTER TABLE Airport
ADD CONSTRAINT CK_Airport_ICAOCode_Length CHECK (LEN(ICAOCode) = 4 OR ICAOCode IS NULL);
GO

-- Creacion del indice en IdCity para optimizar consultas
CREATE INDEX IDX_Airport_IdCity ON Airport(IdCity);
GO

-- Creación de la tabla Plane_Model con atributos adicionales
IF OBJECT_ID('Plane_Model', 'U') IS NULL 
BEGIN
  CREATE TABLE Plane_Model (
    Id NVARCHAR(50) PRIMARY KEY,  -- Identificador alfanumérico como clave primaria
    Manufacturer NVARCHAR(100) NOT NULL,  -- Fabricante del avión
    ModelNumber NVARCHAR(50) NOT NULL,  -- Número de modelo del avión
    Capacity INT NOT NULL,  -- Capacidad de pasajeros
    Range DECIMAL(10, 2) NULL,  -- Rango máximo de vuelo en kilómetros o millas
    Engines INT NOT NULL CHECK (Engines > 0),  -- Número de motores
    MaxTakeoffWeight DECIMAL(10, 2) NULL,  -- Peso máximo al despegue en toneladas
    CruisingSpeed DECIMAL(10, 2) NULL,  -- Velocidad de crucero en km/h o mph
    FirstFlightDate DATE NULL,  -- Fecha del primer vuelo del modelo
    IsInProduction BIT NOT NULL DEFAULT 1,  -- Indica si el modelo aún está en producción (1: sí, 0: no)
    Description NVARCHAR(255) NULL,  -- Descripción opcional del modelo de avión
    Graphic NVARCHAR(255) NULL  -- Ruta o URL del gráfico del modelo de avión
  );
  PRINT 'Tabla Plane_Model creada.';
  
  -- Crear un índice no agrupado en Description para mejorar el rendimiento de las consultas
  CREATE NONCLUSTERED INDEX IX_PlaneModel_Description ON Plane_Model(Description);
  PRINT 'Índice no agrupado en Description creado.';
END
GO

-- Reglas adicionales para asegurar la integridad de los datos
ALTER TABLE Plane_Model
ADD CONSTRAINT CK_PlaneModel_ModelNumber_Length CHECK (LEN(ModelNumber) >= 2);  -- El número de modelo debe tener al menos 2 caracteres
GO

-- Asegurar que la capacidad de pasajeros sea mayor que 0
ALTER TABLE Plane_Model
ADD CONSTRAINT CK_PlaneModel_Capacity_Positive CHECK (Capacity > 0);
GO

-- Creación de la tabla Airplane sin los atributos LastMaintenanceDate, NextMaintenanceDate, MaxPayload e IsLeased
IF OBJECT_ID('Airplane', 'U') IS NULL 
BEGIN
  CREATE TABLE Airplane (
    RegistrationNumber NVARCHAR(50) PRIMARY KEY,  -- Número de registro como clave primaria
    BeginOfOperation DATE NOT NULL,  -- Fecha de inicio de operación obligatoria
    Status NVARCHAR(50) NULL DEFAULT 'Active',  -- Estado del avión con valor predeterminado 'Active'
    PlaneModel_Id NVARCHAR(50) NULL,  -- Clave foránea hacia Plane_Model
    FlightHours DECIMAL(10, 2) NOT NULL DEFAULT 0,  -- Número de horas de vuelo acumuladas
    HomeBase NVARCHAR(50) NULL,  -- Aeropuerto principal donde está basado el avión
    FuelCapacity DECIMAL(10, 2) NULL,  -- Capacidad de combustible en litros o galones
    LeaseExpiryDate DATE NULL,  -- Fecha de expiración del contrato de leasing (si aplica)
    FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE SET NULL  -- Relación con Plane_Model
  );
  PRINT 'Tabla Airplane creada.';
  
  -- Crear un índice no agrupado en Status para mejorar el rendimiento de las consultas por estado
  CREATE NONCLUSTERED INDEX IX_Airplane_Status ON Airplane(Status);
  PRINT 'Índice no agrupado en Status creado.';

  -- Crear un índice no agrupado en PlaneModel_Id para optimizar las consultas por modelo de avión
  CREATE NONCLUSTERED INDEX IX_Airplane_PlaneModel_Id ON Airplane(PlaneModel_Id);
  PRINT 'Índice no agrupado en PlaneModel_Id creado.';
END
GO

-- Reglas adicionales para asegurar la integridad de los datos
ALTER TABLE Airplane
ADD CONSTRAINT CK_Airplane_RegistrationNumber_Length CHECK (LEN(RegistrationNumber) >= 5);  -- El número de registro debe tener al menos 5 caracteres
GO
ALTER TABLE Airplane
ADD CONSTRAINT CK_Airplane_Status CHECK (Status IN ('Active', 'Inactive', 'Maintenance') OR Status IS NULL);  -- Estado válido o NULL
GO
ALTER TABLE Airplane
ADD CONSTRAINT CK_Airplane_BeginOfOperation CHECK (BeginOfOperation <= GETDATE());  -- La fecha de inicio de operación no puede ser en el futuro
GO

-- Asegurar que las horas de vuelo sean positivas
ALTER TABLE Airplane
ADD CONSTRAINT CK_Airplane_FlightHours_Positive CHECK (FlightHours >= 0);
GO

-- Asegurar que la capacidad de combustible sea positiva
ALTER TABLE Airplane
ADD CONSTRAINT CK_Airplane_FuelCapacity_Positive CHECK (FuelCapacity > 0 OR FuelCapacity IS NULL);
GO

-- Asegurar que la fecha de expiración del leasing sea válida si el avión tiene un contrato de leasing
ALTER TABLE Airplane
ADD CONSTRAINT CK_Airplane_LeaseExpiryDate CHECK (LeaseExpiryDate IS NULL OR LeaseExpiryDate >= GETDATE());
GO


-- Creación de la tabla Customer 
IF OBJECT_ID('Customer', 'U') IS NULL 
BEGIN
  CREATE TABLE Customer (
    IdCustomer INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Name NVARCHAR(255) NOT NULL,  -- Nombre del cliente
    DateOfBirth DATE NOT NULL,  -- Fecha de nacimiento
    Email NVARCHAR(255) UNIQUE NOT NULL,  -- Correo electrónico único
    PhoneNumber NVARCHAR(15) NULL,  -- Número de teléfono (opcional)
    Nationality NVARCHAR(100) NULL,  -- Nacionalidad del cliente
    Gender NVARCHAR(10) NULL,  -- Género del cliente (opcional)
    RegistrationDate DATE NOT NULL DEFAULT GETDATE()  -- Fecha de registro con valor predeterminado a la fecha actual
  );
  PRINT 'Tabla Customer creada.';
END
GO

-- Reglas adicionales para asegurar la integridad de los datos

-- Verificar que la fecha de nacimiento sea en el pasado
ALTER TABLE Customer
ADD CONSTRAINT CK_Customer_DateOfBirth CHECK (DateOfBirth < GETDATE());
GO

-- Validar el número de teléfono (10 dígitos numéricos) o permitir NULL
ALTER TABLE Customer
ADD CONSTRAINT CK_Customer_PhoneNumber CHECK (PhoneNumber LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR PhoneNumber IS NULL);
GO

-- Verificación básica para el formato del correo electrónico
ALTER TABLE Customer
ADD CONSTRAINT CK_Customer_Email_Format CHECK (Email LIKE '%@%.%');
GO

-- Asegurar que el género sea uno de los valores esperados o NULL
ALTER TABLE Customer
ADD CONSTRAINT CK_Customer_Gender CHECK (Gender IN ('Male', 'Female', 'Other') OR Gender IS NULL);
GO

-- Crear un índice no agrupado en Email para mejorar las consultas por Email
CREATE NONCLUSTERED INDEX IX_Customer_Email ON Customer(Email);
GO

-- Crear un índice no agrupado en PhoneNumber para mejorar las consultas por teléfono
CREATE NONCLUSTERED INDEX IX_Customer_PhoneNumber ON Customer(PhoneNumber);
GO


-- Creación de la tabla Frequent_Flyer_Card 
IF OBJECT_ID('Frequent_Flyer_Card', 'U') IS NULL 
BEGIN
  CREATE TABLE Frequent_Flyer_Card (
    FCC_Number NVARCHAR(50) PRIMARY KEY,  -- Número de la tarjeta de viajero frecuente (clave primaria)
    Miles INT NOT NULL,  -- Millas acumuladas
    IdCustomer INT NOT NULL  -- Clave foránea hacia Customer
  );
  PRINT 'Tabla Frequent_Flyer_Card creada.';
END
GO

-- Agregar la clave foránea para relacionar con Customer
ALTER TABLE Frequent_Flyer_Card
ADD CONSTRAINT FK_FrequentFlyerCard_Customer FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE;
GO

-- Agregar la restricción para que las millas no sean negativas
ALTER TABLE Frequent_Flyer_Card
ADD CONSTRAINT CK_FrequentFlyerCard_Miles CHECK (Miles >= 0);
GO


-- Creación de la tabla Flight_Number 
IF OBJECT_ID('Flight_Number', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight_Number (
    IdFlightNumber INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    DepartureTime DATETIME NOT NULL,  -- Hora de salida del vuelo
    Description NVARCHAR(255) NULL,  -- Descripción opcional del vuelo
    Type NVARCHAR(50) NULL,  -- Tipo de vuelo (por ejemplo, doméstico, internacional)
    Airline NVARCHAR(50) NOT NULL,  -- Aerolínea del vuelo
    Start_Airport NVARCHAR(255) NOT NULL,  -- Aeropuerto de salida
    Goal_Airport NVARCHAR(255) NOT NULL,  -- Aeropuerto de llegada
    PlaneModel_Id NVARCHAR(50) NULL  -- Modelo del avión usado en el vuelo
  );
  PRINT 'Tabla Flight_Number creada.';
END
GO

-- Agregar clave foránea para Start_Airport
ALTER TABLE Flight_Number
ADD CONSTRAINT FK_FlightNumber_Start_Airport FOREIGN KEY (Start_Airport) REFERENCES Airport(Name) ON DELETE NO ACTION;
GO

-- Agregar clave foránea para Goal_Airport
ALTER TABLE Flight_Number
ADD CONSTRAINT FK_FlightNumber_Goal_Airport FOREIGN KEY (Goal_Airport) REFERENCES Airport(Name) ON DELETE NO ACTION;
GO

-- Agregar clave foránea para PlaneModel_Id
ALTER TABLE Flight_Number
ADD CONSTRAINT FK_FlightNumber_PlaneModel FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE SET NULL;
GO


-- Creación de la tabla Flight_Category con reglas de integridad y seguridad
IF OBJECT_ID('Flight_Category', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight_Category (
    IdFlightCategory INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Name NVARCHAR(255) NOT NULL,  -- Nombre de la categoría de vuelo
    Description NVARCHAR(255) NULL  -- Descripción opcional
  );
  PRINT 'Tabla Flight_Category creada.';
END
GO

-- Agregar restricción de unicidad para el campo Name
ALTER TABLE Flight_Category
ADD CONSTRAINT UQ_FlightCategory_Name UNIQUE (Name);
GO

-- Reglas adicionales para asegurar la integridad de los datos
ALTER TABLE Flight_Category
ADD CONSTRAINT CK_FlightCategory_Name_Length CHECK (LEN(Name) >= 3);  -- El nombre de la categoría debe tener al menos 3 caracteres
GO


-- Creación de la tabla Flight con reglas de integridad, claves foráneas y seguridad
IF OBJECT_ID('Flight', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight (
    IdFlight INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    BoardingTime DATETIME NOT NULL,  -- Hora de embarque
    FlightDate DATE NOT NULL,  -- Fecha del vuelo
    Gate NVARCHAR(50) NULL,  -- Puerta de embarque opcional
    CheckInCounter NVARCHAR(50) NULL,  -- Mostrador de check-in opcional
    IdFlightNumber INT NOT NULL,  -- Clave foránea hacia Flight_Number
    Description NVARCHAR(255) NULL,  -- Descripción opcional
    IdFlightCategory INT NULL  -- Clave foránea hacia Flight_Category
  );
  PRINT 'Tabla Flight creada.';
END
GO

-- Agregar clave foránea para Flight_Number
ALTER TABLE Flight
ADD CONSTRAINT FK_Flight_FlightNumber FOREIGN KEY (IdFlightNumber) REFERENCES Flight_Number(IdFlightNumber) ON DELETE CASCADE;
GO

-- Agregar clave foránea para Flight_Category
ALTER TABLE Flight
ADD CONSTRAINT FK_Flight_FlightCategory FOREIGN KEY (IdFlightCategory) REFERENCES Flight_Category(IdFlightCategory) ON DELETE SET NULL;
GO


-- Creación de la tabla Seat con reglas de integridad, claves foráneas y seguridad
IF OBJECT_ID('Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Seat (
    IdSeat INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Size NVARCHAR(50) NOT NULL,  -- Tamaño del asiento
    Number NVARCHAR(50) NOT NULL,  -- Número del asiento
    Location NVARCHAR(255) NULL,  -- Ubicación opcional del asiento (ejemplo: pasillo, ventana)
    PlaneModel_Id NVARCHAR(50) NOT NULL  -- Clave foránea hacia Plane_Model
  );
  PRINT 'Tabla Seat creada.';
END
GO

-- Agregar clave foránea para PlaneModel_Id
ALTER TABLE Seat
ADD CONSTRAINT FK_Seat_PlaneModel FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE CASCADE;
GO

-- Agregar restricción para longitud mínima del número de asiento
ALTER TABLE Seat
ADD CONSTRAINT CK_Seat_Number_Length CHECK (LEN(Number) >= 1);
GO

-- Agregar restricción para longitud mínima del tamaño del asiento
ALTER TABLE Seat
ADD CONSTRAINT CK_Seat_Size_Length CHECK (LEN(Size) >= 2);
GO


-- Creación de la tabla Available_Seat con reglas de integridad y claves foráneas
IF OBJECT_ID('Available_Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Available_Seat (
    IdAvailableSeat INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    IdFlight INT NOT NULL,  -- Clave foránea hacia Flight
    IdSeat INT NOT NULL  -- Clave foránea hacia Seat
  );
  PRINT 'Tabla Available_Seat creada.';
END
GO

-- Agregar clave foránea para IdFlight
ALTER TABLE Available_Seat
ADD CONSTRAINT FK_AvailableSeat_Flight FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE CASCADE;
GO

-- Agregar clave foránea para IdSeat
ALTER TABLE Available_Seat
ADD CONSTRAINT FK_AvailableSeat_Seat FOREIGN KEY (IdSeat) REFERENCES Seat(IdSeat) ON DELETE CASCADE;
GO

-- Creación de la tabla Ticket con atributos adicionales
IF OBJECT_ID('Ticket', 'U') IS NULL 
BEGIN
  CREATE TABLE Ticket (
    TicketingCode NVARCHAR(50) PRIMARY KEY,  -- Clave primaria para el código de ticket
    Number NVARCHAR(50) NOT NULL,  -- Número del ticket, debe ser único
    IssueDate DATE NOT NULL DEFAULT GETDATE(),  -- Fecha en la que se emitió el ticket
    ExpirationDate DATE NULL,  -- Fecha de expiración del ticket (opcional)
    TicketStatus NVARCHAR(50) NOT NULL DEFAULT 'Active',  -- Estado del ticket (Active, Cancelled, Used)
    ClassType NVARCHAR(50) NOT NULL,  -- Clase del ticket (Economy, Business, First Class)
    Price DECIMAL(10, 2) NOT NULL,  -- Precio del ticket
    IdCustomer INT NOT NULL  -- Clave foránea hacia Customer
  );
  PRINT 'Tabla Ticket creada.';
END
GO

-- Agregar restricción de unicidad para el campo Number
ALTER TABLE Ticket
ADD CONSTRAINT UQ_Ticket_Number UNIQUE (Number);
GO

-- Agregar clave foránea para IdCustomer
ALTER TABLE Ticket
ADD CONSTRAINT FK_Ticket_Customer FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE;
GO

-- Asegurar que la fecha de emisión sea anterior o igual a la fecha de expiración
ALTER TABLE Ticket
ADD CONSTRAINT CK_Ticket_IssueDate CHECK (ExpirationDate IS NULL OR ExpirationDate > IssueDate);
GO

-- Asegurar que el estado del ticket sea uno de los valores válidos
ALTER TABLE Ticket
ADD CONSTRAINT CK_Ticket_Status CHECK (TicketStatus IN ('Active', 'Cancelled', 'Used'));
GO

-- Asegurar que el precio del ticket sea mayor a 0
ALTER TABLE Ticket
ADD CONSTRAINT CK_Ticket_Price_Positive CHECK (Price > 0);
GO

-- Asegurar que el tipo de clase sea uno de los valores válidos
ALTER TABLE Ticket
ADD CONSTRAINT CK_Ticket_ClassType CHECK (ClassType IN ('Economy', 'Business', 'First Class'));
GO


-- Creación de la tabla Coupon con atributos adicionales
IF OBJECT_ID('Coupon', 'U') IS NULL 
BEGIN
  CREATE TABLE Coupon (
    IdCoupon INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    TicketingCode NVARCHAR(50) NOT NULL,  -- Clave foránea hacia Ticket
    Number NVARCHAR(50) NOT NULL,  -- Número del cupón
    Standby BIT NOT NULL DEFAULT 0,  -- Estado de espera (1: Sí, 0: No), predeterminado a 0
    MealCode NVARCHAR(50) NULL,  -- Código de la comida (opcional)
    IssuedDate DATE NOT NULL DEFAULT GETDATE(),  -- Fecha de emisión del cupón, por defecto la fecha actual
    ExpirationDate DATE NULL,  -- Fecha de expiración del cupón (opcional)
    IsRefundable BIT NOT NULL DEFAULT 0,  -- Indica si el cupón es reembolsable
    CouponStatus NVARCHAR(50) NOT NULL DEFAULT 'Active',  -- Estado del cupón (Active, Used, Expired)
    BaggageAllowance INT NOT NULL DEFAULT 0,  -- Equipaje permitido en kg asociado al cupón
    IdFlight INT NOT NULL,  -- Clave foránea hacia Flight
    IdAvailableSeat INT NOT NULL  -- Clave foránea hacia Available_Seat
  );
  PRINT 'Tabla Coupon creada.';
END
GO

-- Agregar clave foránea para TicketingCode
ALTER TABLE Coupon
ADD CONSTRAINT FK_Coupon_Ticket FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE;
GO

-- Agregar clave foránea para IdFlight
ALTER TABLE Coupon
ADD CONSTRAINT FK_Coupon_Flight FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE NO ACTION;
GO

-- Agregar clave foránea para IdAvailableSeat
ALTER TABLE Coupon
ADD CONSTRAINT FK_Coupon_AvailableSeat FOREIGN KEY (IdAvailableSeat) REFERENCES Available_Seat(IdAvailableSeat) ON DELETE NO ACTION;
GO

-- Asegurar que la fecha de emisión sea anterior a la fecha de expiración
ALTER TABLE Coupon
ADD CONSTRAINT CK_Coupon_IssuedDate CHECK (ExpirationDate IS NULL OR ExpirationDate > IssuedDate);
GO

-- Asegurar que el estado del cupón sea uno de los valores válidos
ALTER TABLE Coupon
ADD CONSTRAINT CK_Coupon_Status CHECK (CouponStatus IN ('Active', 'Used', 'Expired'));
GO

-- Asegurar que la cantidad de equipaje permitido no sea negativa
ALTER TABLE Coupon
ADD CONSTRAINT CK_Coupon_BaggageAllowance CHECK (BaggageAllowance >= 0);
GO


-- Creación de la tabla Pieces_of_Luggage con atributos adicionales
IF OBJECT_ID('Pieces_of_Luggage', 'U') IS NULL 
BEGIN
  CREATE TABLE Pieces_of_Luggage (
    IdLuggage INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Number NVARCHAR(50) NOT NULL,  -- Número de identificación del equipaje
    Weight DECIMAL(5, 2) NOT NULL,  -- Peso del equipaje
    Dimensions NVARCHAR(50) NULL,  -- Dimensiones del equipaje (LxWxH)
    IsOversized BIT NOT NULL DEFAULT 0,  -- Indica si el equipaje es de tamaño excesivo (1: Sí, 0: No)
    LuggageType NVARCHAR(50) NOT NULL,  -- Tipo de equipaje (Maleta, Mochila, etc.)
    HandlingCode NVARCHAR(50) NULL,  -- Código especial para el manejo del equipaje (Fragile, Heavy, etc.)
    IdCoupon INT NOT NULL  -- Clave foránea hacia Coupon
  );
  PRINT 'Tabla Pieces_of_Luggage creada.';
END
GO

-- Agregar restricciones de validación para Number, Weight, y Dimensions
ALTER TABLE Pieces_of_Luggage
ADD CONSTRAINT CK_Pieces_of_Luggage_Number_Length CHECK (LEN(Number) <= 50);
GO

ALTER TABLE Pieces_of_Luggage
ADD CONSTRAINT CK_Pieces_of_Luggage_Weight CHECK (Weight >= 0);
GO

-- Asegurar que las dimensiones estén en el formato correcto (por ejemplo, "LxWxH")
ALTER TABLE Pieces_of_Luggage
ADD CONSTRAINT CK_Pieces_of_Luggage_Dimensions_Format CHECK (Dimensions LIKE '[0-9][0-9]x[0-9][0-9]x[0-9][0-9]' OR Dimensions IS NULL);
GO

-- Asegurar que el tipo de equipaje esté en valores esperados
ALTER TABLE Pieces_of_Luggage
ADD CONSTRAINT CK_Pieces_of_Luggage_Type CHECK (LuggageType IN ('Maleta', 'Mochila', 'Caja', 'Bolsa', 'Otro'));
GO

-- Agregar clave foránea para IdCoupon
ALTER TABLE Pieces_of_Luggage
ADD CONSTRAINT FK_Pieces_of_Luggage_Coupon FOREIGN KEY (IdCoupon) REFERENCES Coupon(IdCoupon) ON DELETE CASCADE;
GO


-- Creación de la tabla Payment_Method con atributos adicionales
IF OBJECT_ID('Payment_Method', 'U') IS NULL 
BEGIN
  CREATE TABLE Payment_Method (
    IdPaymentMethod INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Name NVARCHAR(50) NOT NULL,  -- Nombre del método de pago
    Description NVARCHAR(255) NULL,  -- Descripción opcional del método de pago
    IsActive BIT NOT NULL DEFAULT 1,  -- Indica si el método de pago está activo (1) o inactivo (0)
    ProcessingFee DECIMAL(10, 2) NULL,  -- Tarifa de procesamiento asociada al método de pago
    PaymentGateway NVARCHAR(50) NULL,  -- Gateway de pago asociado (por ejemplo, PayPal, Stripe)
    MaxTransactionLimit DECIMAL(10, 2) NULL,  -- Límite máximo por transacción
    CurrencySupported NVARCHAR(10) NULL DEFAULT 'USD'  -- Moneda admitida por este método de pago (predeterminado USD)
  );
  PRINT 'Tabla Payment_Method creada.';
END
GO

-- Agregar restricción para asegurar la longitud mínima del nombre del método de pago
ALTER TABLE Payment_Method
ADD CONSTRAINT CK_PaymentMethod_Name_Length CHECK (LEN(Name) >= 3);
GO

-- Asegurar que la tarifa de procesamiento sea positiva si se proporciona
ALTER TABLE Payment_Method
ADD CONSTRAINT CK_PaymentMethod_ProcessingFee_Positive CHECK (ProcessingFee >= 0 OR ProcessingFee IS NULL);
GO

-- Asegurar que el límite máximo por transacción sea positivo si se proporciona
ALTER TABLE Payment_Method
ADD CONSTRAINT CK_PaymentMethod_MaxTransactionLimit_Positive CHECK (MaxTransactionLimit >= 0 OR MaxTransactionLimit IS NULL);
GO



-- Creación de la tabla Payment con atributos adicionales
IF OBJECT_ID('Payment', 'U') IS NULL 
BEGIN
  CREATE TABLE Payment (
    IdPayment INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Amount DECIMAL(10, 2) NOT NULL,  -- Monto del pago
    Currency NVARCHAR(10) NOT NULL DEFAULT 'USD',  -- Moneda del pago (predeterminado: USD)
    PaymentDate DATE NOT NULL,  -- Fecha de pago
    ConfirmationDate DATE NULL,  -- Fecha de confirmación del pago (opcional)
    PaymentStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending',  -- Estado del pago (Pending, Completed, Failed, etc.)
    TransactionNumber NVARCHAR(100) NULL,  -- Número de transacción único
    IdPaymentMethod INT NOT NULL,  -- Clave foránea hacia Payment_Method
    TicketingCode NVARCHAR(50) NOT NULL  -- Clave foránea hacia Ticket
  );
  PRINT 'Tabla Payment creada.';
END
GO

-- Agregar restricción para asegurar que el monto sea positivo
ALTER TABLE Payment
ADD CONSTRAINT CK_Payment_Amount_Positive CHECK (Amount > 0);
GO

-- Asegurar que el estado del pago sea uno de los valores válidos
ALTER TABLE Payment
ADD CONSTRAINT CK_Payment_Status CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded'));
GO

-- Asegurar que la fecha de confirmación, si existe, sea posterior o igual a la fecha de pago
ALTER TABLE Payment
ADD CONSTRAINT CK_Payment_ConfirmationDate CHECK (ConfirmationDate >= PaymentDate OR ConfirmationDate IS NULL);
GO

-- Agregar clave foránea para IdPaymentMethod
ALTER TABLE Payment
ADD CONSTRAINT FK_Payment_PaymentMethod FOREIGN KEY (IdPaymentMethod) REFERENCES Payment_Method(IdPaymentMethod) ON DELETE NO ACTION;
GO

-- Agregar clave foránea para TicketingCode
ALTER TABLE Payment
ADD CONSTRAINT FK_Payment_Ticket FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE;
GO



-- Creación de la tabla Sales_Invoice con reglas de integridad y claves foráneas
IF OBJECT_ID('Sales_Invoice', 'U') IS NULL 
BEGIN
  CREATE TABLE Sales_Invoice (
    IdSalesInvoice INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    TicketingCode NVARCHAR(50) NOT NULL,  -- Clave foránea hacia Ticket
    SaleDate DATE NOT NULL,  -- Fecha de la venta
    TotalAmount DECIMAL(10, 2) NOT NULL  -- Monto total de la venta
  );
  PRINT 'Tabla Sales_Invoice creada.';
END
GO

-- Agregar restricción para asegurar que el monto total sea positivo
ALTER TABLE Sales_Invoice
ADD CONSTRAINT CK_Sales_Invoice_TotalAmount_Positive CHECK (TotalAmount > 0);
GO

-- Agregar clave foránea para TicketingCode
ALTER TABLE Sales_Invoice
ADD CONSTRAINT FK_Sales_Invoice_Ticket FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE;
GO


-- Creación de la tabla Reservation con reglas de integridad, claves foráneas y restricciones de fecha
IF OBJECT_ID('Reservation', 'U') IS NULL 
BEGIN
  CREATE TABLE Reservation (
    ReservationDate DATE NOT NULL,  -- Fecha de la reserva
    PaymentDueDate DATE NOT NULL,  -- Fecha límite de pago
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',  -- Estado de la reserva, predeterminado a 'Pending'
    TotalPrice DECIMAL(10, 2) NOT NULL,  -- Precio total de la reserva
    TicketingCode NVARCHAR(50) NOT NULL,  -- Clave foránea hacia Ticket
    PRIMARY KEY (TicketingCode)  -- La clave primaria es el código del ticket
  );
  PRINT 'Tabla Reservation creada.';
END
GO

-- Agregar restricción para asegurar que el precio total sea positivo
ALTER TABLE Reservation
ADD CONSTRAINT CK_Reservation_TotalPrice_Positive CHECK (TotalPrice > 0);
GO

-- Agregar restricción para asegurar que la fecha de reserva no sea en el pasado
ALTER TABLE Reservation
ADD CONSTRAINT CK_Reservation_ReservationDate CHECK (ReservationDate >= GETDATE());
GO

-- Agregar restricción para asegurar que la fecha límite de pago sea igual o posterior a la fecha de reserva
ALTER TABLE Reservation
ADD CONSTRAINT CK_Reservation_PaymentDueDate CHECK (PaymentDueDate >= ReservationDate);
GO

-- Agregar clave foránea para TicketingCode
ALTER TABLE Reservation
ADD CONSTRAINT FK_Reservation_Ticket FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE;
GO


-- Creación de la tabla Ticket_Charge con reglas de integridad, claves foráneas y restricciones de fecha
IF OBJECT_ID('Ticket_Charge', 'U') IS NULL 
BEGIN
  CREATE TABLE Ticket_Charge (
    TicketingCode NVARCHAR(50) NOT NULL,  -- Clave foránea hacia Ticket
    OriginalFlightDate DATE NOT NULL,  -- Fecha original del vuelo
    NewFlightDate DATE NOT NULL,  -- Nueva fecha del vuelo
    ChargeDate DATE NOT NULL,  -- Fecha en la que se realizó el cargo
    PenaltyAmount DECIMAL(10, 2) NOT NULL,  -- Monto de la penalización
    Reason NVARCHAR(200) NULL,  -- Razón del cambio de vuelo o cargo
    PRIMARY KEY (TicketingCode, OriginalFlightDate),  -- Clave primaria compuesta
    FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE NO ACTION  -- Modificado para evitar cascadas múltiples
  );
  PRINT 'Tabla Ticket_Charge creada.';
END
GO

-- Agregar restricción para asegurar que la penalización sea mayor o igual a cero
ALTER TABLE Ticket_Charge
ADD CONSTRAINT CK_Ticket_Charge_PenaltyAmount_Positive CHECK (PenaltyAmount >= 0);
GO

-- Agregar restricción para asegurar que la nueva fecha de vuelo sea igual o posterior a la fecha original del vuelo
ALTER TABLE Ticket_Charge
ADD CONSTRAINT CK_Ticket_Charge_NewFlightDate CHECK (NewFlightDate >= OriginalFlightDate);
GO

-- Agregar restricción para asegurar que la fecha del cargo sea igual o posterior a la fecha original del vuelo
ALTER TABLE Ticket_Charge
ADD CONSTRAINT CK_Ticket_Charge_ChargeDate CHECK (ChargeDate >= OriginalFlightDate);
GO

-- Agregar clave foránea para TicketingCode sin eliminación en cascada
ALTER TABLE Ticket_Charge
ADD CONSTRAINT FK_Ticket_Charge_Ticket FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE NO ACTION;
GO


-- Creación de la tabla Document con atributos específicos para pasaportes y claves foráneas
IF OBJECT_ID('Document', 'U') IS NULL 
BEGIN
  CREATE TABLE Document (
    IdDocument INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    PassportNumber NVARCHAR(50) NOT NULL,  -- Número del pasaporte
    IssueDate DATE NOT NULL,  -- Fecha de emisión del pasaporte
    ExpiryDate DATE NOT NULL,  -- Fecha de expiración del pasaporte
    CountryOfIssue NVARCHAR(100) NOT NULL,  -- País emisor del pasaporte
    Description NVARCHAR(255) NULL,  -- Descripción opcional
    IdCustomer INT NOT NULL,  -- Clave foránea hacia Customer
    FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE  -- Relación con Customer
  );
  PRINT 'Tabla Document creada.';
END
GO

-- Agregar restricción para asegurar que la fecha de expiración sea posterior a la fecha de emisión
ALTER TABLE Document
ADD CONSTRAINT CK_Document_ExpiryDate CHECK (ExpiryDate > IssueDate);
GO

-- Agregar restricción para asegurar que el número de pasaporte tenga al menos 6 caracteres
ALTER TABLE Document
ADD CONSTRAINT CK_Document_PassportNumber_Length CHECK (LEN(PassportNumber) >= 6);
GO


-- Creación de la tabla Reserved_Seat con atributos adicionales
IF OBJECT_ID('Reserved_Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Reserved_Seat (
    IdReservedSeat INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),  -- Precio del asiento reservado
    SeatNumber NVARCHAR(10) NOT NULL,  -- Número del asiento reservado
    FlightNumber NVARCHAR(20) NOT NULL,  -- Número del vuelo asociado al asiento reservado
    Class NVARCHAR(50) NOT NULL,  -- Clase del asiento (económica, ejecutiva, primera clase)
    ReservationDate DATE NOT NULL DEFAULT GETDATE(),  -- Fecha de la reserva
    TicketingCode NVARCHAR(50) NOT NULL,  -- Clave foránea hacia Reservation
    FOREIGN KEY (TicketingCode) REFERENCES Reservation(TicketingCode) ON DELETE CASCADE  -- Relación con Reservation
  );
  PRINT 'Tabla Reserved_Seat creada.';
END
GO

-- Agregar restricción para asegurar que el número de asiento tenga al menos 1 carácter
ALTER TABLE Reserved_Seat
ADD CONSTRAINT CK_Reserved_Seat_SeatNumber_Length CHECK (LEN(SeatNumber) >= 1);
GO

-- Agregar restricción para asegurar que la clase del asiento tenga al menos 3 caracteres
ALTER TABLE Reserved_Seat
ADD CONSTRAINT CK_Reserved_Seat_Class_Length CHECK (LEN(Class) >= 3);
GO


-- Creación de la tabla Checking con atributos adicionales
IF OBJECT_ID('Checking', 'U') IS NULL 
BEGIN
  CREATE TABLE Checking (
    IdChecking INT PRIMARY KEY IDENTITY(1,1),  -- Clave primaria autoincremental
    Seat_Number NVARCHAR(50) NOT NULL,  -- Número del asiento
    Baggage_Count INT NOT NULL CHECK (Baggage_Count >= 0),  -- Cantidad de equipaje
    CheckIn_Time DATETIME NOT NULL,  -- Hora de check-in
    Boarding_Time DATETIME NOT NULL,  -- Hora de embarque
    GateNumber NVARCHAR(10) NULL,  -- Número de la puerta de embarque
    CheckInStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending',  -- Estado del check-in (por ejemplo, Completado, En proceso)
    DocumentVerificationStatus BIT NOT NULL DEFAULT 0,  -- Estado de verificación de documentos (1: Verificado, 0: No verificado)
    AdditionalBaggageFee DECIMAL(10, 2) NULL,  -- Tarifa adicional por exceso de equipaje
    Status NVARCHAR(50) NULL DEFAULT 'Pending',  -- Estado general del proceso de check-in
    IdTicket NVARCHAR(50) NOT NULL,  -- Clave foránea hacia Ticket
    IdFlight INT NOT NULL,  -- Clave foránea hacia Flight
    FOREIGN KEY (IdTicket) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE,  -- Relación con Ticket
    FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE CASCADE  -- Relación con Flight
  );
  PRINT 'Tabla Checking creada.';
END
GO

-- Agregar restricción para asegurar que el número de la puerta de embarque tenga al menos 1 carácter si se proporciona
ALTER TABLE Checking
ADD CONSTRAINT CK_Checking_GateNumber_Length CHECK (LEN(GateNumber) >= 1 OR GateNumber IS NULL);
GO

-- Agregar restricción para asegurar que la tarifa adicional por equipaje sea mayor o igual a cero si se proporciona
ALTER TABLE Checking
ADD CONSTRAINT CK_Checking_AdditionalBaggageFee_Positive CHECK (AdditionalBaggageFee >= 0 OR AdditionalBaggageFee IS NULL);
GO


---------------------- LLAMADAS SELECT -------------------

-- Seleccionar todos los registros de cada tabla
-- Seleccionar todos los registros de la tabla Country (País)
SELECT * FROM Country;

-- Seleccionar todos los registros de la tabla City (Ciudad)
SELECT * FROM City;

-- Seleccionar todos los registros de la tabla Airport (Aeropuerto)
SELECT * FROM Airport;

-- Seleccionar todos los registros de la tabla Plane_Model (Modelo de Avión)
SELECT * FROM Plane_Model;

-- Seleccionar todos los registros de la tabla Airplane (Avión)
SELECT * FROM Airplane;

-- Seleccionar todos los registros de la tabla Customer (Cliente)
SELECT * FROM Customer;

-- Seleccionar todos los registros de la tabla Frequent_Flyer_Card (Tarjeta de Viajero Frecuente)
SELECT * FROM Frequent_Flyer_Card;

-- Seleccionar todos los registros de la tabla Flight_Number (Número de Vuelo)
SELECT * FROM Flight_Number;

-- Seleccionar todos los registros de la tabla Flight (Vuelo)
SELECT * FROM Flight;

-- Seleccionar todos los registros de la tabla Seat (Asiento)
SELECT * FROM Seat;

-- Seleccionar todos los registros de la tabla Available_Seat (Asiento Disponible)
SELECT * FROM Available_Seat;

-- Seleccionar todos los registros de la tabla Ticket (Boleto)
SELECT * FROM Ticket;

-- Seleccionar todos los registros de la tabla Coupon (Cupón)
SELECT * FROM Coupon;

-- Seleccionar todos los registros de la tabla Pieces_of_Luggage (Piezas de Equipaje)
SELECT * FROM Pieces_of_Luggage;

-- Seleccionar todos los registros de la tabla Payment_Method (Método de Pago)
SELECT * FROM Payment_Method;

-- Seleccionar todos los registros de la tabla Payment (Pago)
SELECT * FROM Payment;

-- Seleccionar todos los registros de la tabla Sales_Invoice (Factura de Venta)
SELECT * FROM Sales_Invoice;

-- Seleccionar todos los registros de la tabla Reservation (Reserva)
SELECT * FROM Reservation;

-- Seleccionar todos los registros de la tabla Ticket_Charge (Cargo por Boleto)
SELECT * FROM Ticket_Charge;

-- Seleccionar todos los registros de la tabla Document (Documento)
SELECT * FROM Document;

-- Seleccionar todos los registros de la tabla Reserved_Seat (Asiento Reservado)
SELECT * FROM Reserved_Seat;

-- Seleccionar todos los registros de la tabla Checking (Chequeo)
SELECT * FROM Checking;


GO
