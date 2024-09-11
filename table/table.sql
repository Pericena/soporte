USE MASTER;
BEGIN TRY
    -- Verificar si la base de datos existe
    IF DB_ID('AirlineDB') IS NOT NULL
    BEGIN
        -- Establecer la base de datos en modo de usuario �nico y cerrar todas las conexiones activas
        ALTER DATABASE AirlineDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        PRINT 'Conexiones activas cerradas.';

        -- Intentar eliminar la base de datos
        DROP DATABASE AirlineDB;
        PRINT 'Base de datos AirlineDB eliminada.';
    END
END TRY
BEGIN CATCH
    -- Capturar el error y verificar si es el error 3702
    IF ERROR_NUMBER() = 3702
    BEGIN
        PRINT 'No se puede quitar la base de datos ''AirlineDB''; est� en uso.';
    END
    ELSE
    BEGIN
        -- Si ocurre un error diferente, mostrar el mensaje de error est�ndar
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

-- Usar la base de datos reci�n creada
USE AirlineDB;
GO

-- Creaci�n de la tabla Country
IF OBJECT_ID('Country', 'U') IS NULL 
BEGIN
  CREATE TABLE Country (
    IdCountry INT PRIMARY KEY,  -- Clave primaria, regla de integridad que garantiza que cada pa�s tenga un identificador �nico
    NameC NVARCHAR(255) NOT NULL UNIQUE  -- Regla de integridad: NOT NULL y UNIQUE, garantiza que el nombre del pa�s sea �nico y no nulo
  );
  PRINT 'Tabla Country creada.';
END
GO

-- Creaci�n de la tabla City
IF OBJECT_ID('City', 'U') IS NULL 
BEGIN
  CREATE TABLE City (
    IdCity INT PRIMARY KEY,  -- Clave primaria, garantiza que cada ciudad tenga un identificador �nico
    Name NVARCHAR(255) NOT NULL,  -- Nombre de la ciudad, no nulo
    IdCountry INT NOT NULL,  -- Clave for�nea, debe referenciar a Country (no nulo)
    FOREIGN KEY (IdCountry) REFERENCES Country(IdCountry) ON DELETE CASCADE  -- Regla de integridad: Clave for�nea con eliminaci�n en cascada, se eliminan las ciudades si el pa�s se elimina
  );
  PRINT 'Tabla City creada.';
END
GO



-- Creación de la tabla Airport
IF OBJECT_ID('Airport', 'U') IS NULL 
BEGIN
  CREATE TABLE Airport (
        IdAirport INT PRIMARY KEY,  -- Clave primaria única para el aeropuerto
        Name NVARCHAR(255) NOT NULL UNIQUE,  -- Nombre del aeropuerto, debe ser único y no nulo
        IdCity INT NULL,  -- Referencia a la ciudad, permite valores nulos
        Latitude DECIMAL(9, 6) NOT NULL,  -- Latitud con precisión, no nula
        Longitude DECIMAL(9, 6) NOT NULL,  -- Longitud con precisión, no nula
        Description NVARCHAR(255) NULL,  -- Descripción opcional
        FOREIGN KEY (IdCity) REFERENCES City(IdCity) ON DELETE SET NULL  -- Regla de integridad: Si la ciudad es eliminada, se establece el campo en NULL
  );
  PRINT 'Tabla Airport creada.';
END
GO


-- Creaci�n de la tabla Plane_Model
IF OBJECT_ID('Plane_Model', 'U') IS NULL 
BEGIN
  CREATE TABLE Plane_Model (
    Id NVARCHAR(50) PRIMARY KEY,  -- Clave primaria, cada modelo de avi�n debe tener un identificador �nico
    Description NVARCHAR(255) NULL,  -- Descripci�n del modelo, opcional
    Graphic NVARCHAR(255) NULL  -- Enlace o gr�fico del modelo, opcional
  );
  PRINT 'Tabla Plane_Model creada.';
END
GO

-- Creaci�n de la tabla Airplane
IF OBJECT_ID('Airplane', 'U') IS NULL 
BEGIN
  CREATE TABLE Airplane (
    RegistrationNumber NVARCHAR(50) PRIMARY KEY,  -- Clave primaria, el n�mero de registro del avi�n debe ser �nico
    BeginOfOperation DATE NOT NULL,  -- Fecha de inicio de operaci�n, no nulo
    Status NVARCHAR(50) NULL,  -- Estado del avi�n, opcional
    PlaneModel_Id NVARCHAR(50) NULL,  -- Referencia al modelo de avi�n, puede ser nulo
    FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE SET NULL  -- Regla de integridad: Si el modelo de avi�n es eliminado, se establece como NULL
  );
  PRINT 'Tabla Airplane creada.';
END
GO


-- Creaci�n de la tabla Customer
IF OBJECT_ID('Customer', 'U') IS NULL 
BEGIN
  CREATE TABLE Customer (
    IdCustomer INT PRIMARY KEY,  -- Clave primaria, identificador �nico del cliente
    Name NVARCHAR(255) NULL,  -- Nombre del cliente, opcional
    DateOfBirth DATE NULL  -- Fecha de nacimiento del cliente, opcional
  );
  PRINT 'Tabla Customer creada.';
END
GO

-- Creaci�n de la tabla Frequent_Flyer_Card
IF OBJECT_ID('Frequent_Flyer_Card', 'U') IS NULL 
BEGIN
  CREATE TABLE Frequent_Flyer_Card (
    FCC_Number NVARCHAR(50) PRIMARY KEY,  -- N�mero de la tarjeta, clave primaria
    Miles INT NULL,  -- Millas acumuladas, opcional
    IdCustomer INT NOT NULL,  -- Referencia al cliente, obligatorio
    FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE  -- Regla de integridad: Si se elimina el cliente, la tarjeta es eliminada autom�ticamente
  );
  PRINT 'Tabla Frequent_Flyer_Card creada.';
END
GO


-- Creaci�n de la tabla Flight_Number
IF OBJECT_ID('Flight_Number', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight_Number (
    IdFlightNumber INT PRIMARY KEY,  -- Clave primaria, identificador �nico para el n�mero de vuelo
    DepartureTime DATETIME NOT NULL,  -- Hora de salida, obligatoria
    Description NVARCHAR(255) NULL,  -- Descripci�n del vuelo, opcional
    Type NVARCHAR(50) NULL,  -- Tipo de vuelo, opcional
    Airline NVARCHAR(50) NULL,  -- Nombre de la aerol�nea, opcional
    Start_Airport NVARCHAR(255) NOT NULL,  -- Aeropuerto de salida, obligatorio
    Goal_Airport NVARCHAR(255) NOT NULL,  -- Aeropuerto de destino, obligatorio
    PlaneModel_Id NVARCHAR(50) NULL,  -- Referencia al modelo del avi�n, puede ser nulo
    FOREIGN KEY (Start_Airport) REFERENCES Airport(Name) ON DELETE NO ACTION,  -- Regla de integridad: No hacer nada al eliminar el aeropuerto de salida
    FOREIGN KEY (Goal_Airport) REFERENCES Airport(Name) ON DELETE NO ACTION,  -- Regla de integridad: No hacer nada al eliminar el aeropuerto de destino
    FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE SET NULL  -- Si se elimina el modelo de avi�n, se establece como NULL
  );
  PRINT 'Tabla Flight_Number creada.';
END
GO


-- Creaci�n de la tabla Flight
IF OBJECT_ID('Flight', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight (
    IdFlight INT PRIMARY KEY,  -- Clave primaria, identificador �nico para el vuelo
    BoardingTime DATETIME NULL,  -- Hora de abordaje, opcional
    FlightDate DATE NULL,  -- Fecha del vuelo, opcional
    Gate NVARCHAR(50) NULL,  -- Puerta de embarque, opcional
    CheckInCounter NVARCHAR(50) NULL,  -- Mostrador de facturaci�n, opcional
    IdFlightNumber INT NOT NULL,  -- Referencia al n�mero de vuelo, obligatorio
    FOREIGN KEY (IdFlightNumber) REFERENCES Flight_Number(IdFlightNumber) ON DELETE CASCADE  -- Regla de integridad: Si se elimina el n�mero de vuelo, se eliminan los vuelos
  );
  PRINT 'Tabla Flight creada.';
END
GO


-- Creaci�n de la tabla Seat
IF OBJECT_ID('Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Seat (
    IdSeat INT PRIMARY KEY,  -- Clave primaria, identificador �nico para el asiento
    Size NVARCHAR(50) NULL,  -- Tama�o del asiento, opcional
    Number NVARCHAR(50) NOT NULL,  -- N�mero del asiento, obligatorio
    Location NVARCHAR(255) NULL,  -- Ubicaci�n del asiento en el avi�n, opcional
    PlaneModel_Id NVARCHAR(50) NOT NULL,  -- Referencia al modelo de avi�n, obligatorio
    FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE CASCADE  -- Regla de integridad: Si se elimina el modelo del avi�n, se eliminan los asientos asociados
  );
  PRINT 'Tabla Seat creada.';
END
GO

-- Creaci�n de la tabla Available_Seat
IF OBJECT_ID('Available_Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Available_Seat (
    IdAvailableSeat INT PRIMARY KEY,  -- Clave primaria, identificador �nico para el asiento disponible
    IdFlight INT NOT NULL,  -- Referencia al vuelo, obligatorio
    IdSeat INT NOT NULL,  -- Referencia al asiento, obligatorio
    FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE CASCADE,  -- Regla de integridad: Si se elimina el vuelo, se eliminan los asientos disponibles asociados
    FOREIGN KEY (IdSeat) REFERENCES Seat(IdSeat) ON DELETE CASCADE  -- Regla de integridad: Si se elimina el asiento, se eliminan los registros asociados
  );
  PRINT 'Tabla Available_Seat creada.';
END
GO



-- Creaci�n de la tabla Ticket
IF OBJECT_ID('Ticket', 'U') IS NULL 
BEGIN
  CREATE TABLE Ticket (
    TicketingCode NVARCHAR(50) PRIMARY KEY,  -- C�digo del ticket, clave primaria
    Number NVARCHAR(50) NOT NULL,  -- N�mero del ticket, obligatorio
    IdCustomer INT NOT NULL,  -- Referencia al cliente, obligatorio
    FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE  -- Regla de integridad: Si se elimina el cliente, se eliminan los tickets
  );
  PRINT 'Tabla Ticket creada.';
END
GO


-- Creaci�n de la tabla Coupon
IF OBJECT_ID('Coupon', 'U') IS NULL 
BEGIN
  CREATE TABLE Coupon (
    IdCoupon INT PRIMARY KEY,  -- Clave primaria, identificador �nico para el cup�n
    TicketingCode NVARCHAR(50) NOT NULL,  -- Referencia al ticket, obligatorio
    Number NVARCHAR(50) NOT NULL,  -- N�mero del cup�n, obligatorio
    Standby BIT NOT NULL,  -- Indica si el pasajero est� en lista de espera, obligatorio
    MealCode NVARCHAR(50) NULL,  -- C�digo de la comida, opcional
    IdFlight INT NOT NULL,  -- Referencia al vuelo, obligatorio
    IdAvailableSeat INT NOT NULL,  -- Referencia al asiento disponible, obligatorio
    FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE,  -- Regla de integridad: Si se elimina el ticket, se eliminan los cupones asociados
    FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE NO ACTION,  -- Regla de integridad: No eliminar cupones al eliminar vuelos
    FOREIGN KEY (IdAvailableSeat) REFERENCES Available_Seat(IdAvailableSeat) ON DELETE NO ACTION  -- Regla de integridad: No eliminar cupones al eliminar asientos
  );
  PRINT 'Tabla Coupon creada.';
END
GO


-- Creación de la tabla Pieces_of_Luggage
IF OBJECT_ID('Pieces_of_Luggage', 'U') IS NULL 
BEGIN
  CREATE TABLE Pieces_of_Luggage (
    IdLuggage INT PRIMARY KEY,  -- Clave primaria, identificador único del equipaje
    Number NVARCHAR(50) NOT NULL CHECK (LEN(Number) <= 50),  -- Número del equipaje, obligatorio y con validación de longitud máxima de 50 caracteres
    Weight DECIMAL(5, 2) NOT NULL CHECK (Weight >= 0),  -- Peso del equipaje, obligatorio y no puede ser negativo
    IdCoupon INT NOT NULL,  -- Referencia al cupón, obligatorio
    FOREIGN KEY (IdCoupon) REFERENCES Coupon(IdCoupon) ON DELETE CASCADE  -- Regla de integridad: Si se elimina el cupón, se elimina el equipaje asociado
  );
  PRINT 'Tabla Pieces_of_Luggage creada.';
END
GO



----------------------llamada--
-- Seleccionar todos los registros de la tabla Country
SELECT * FROM Country;

-- Seleccionar todos los registros de la tabla City
SELECT * FROM City;

-- Seleccionar todos los registros de la tabla Airport
SELECT * FROM Airport;

-- Seleccionar todos los registros de la tabla Plane_Model
SELECT * FROM Plane_Model;

-- Seleccionar todos los registros de la tabla Airplane
SELECT * FROM Airplane;

-- Seleccionar todos los registros de la tabla Customer
SELECT * FROM Customer;

-- Seleccionar todos los registros de la tabla Frequent_Flyer_Card
SELECT * FROM Frequent_Flyer_Card;

-- Seleccionar todos los registros de la tabla Flight_Number
SELECT * FROM Flight_Number;

-- Seleccionar todos los registros de la tabla Flight
SELECT * FROM Flight;

-- Seleccionar todos los registros de la tabla Seat
SELECT * FROM Seat;

-- Seleccionar todos los registros de la tabla Available_Seat
SELECT * FROM Available_Seat;

-- Seleccionar todos los registros de la tabla Ticket
SELECT * FROM Ticket;

-- Seleccionar todos los registros de la tabla Coupon
SELECT * FROM Coupon;

-- Seleccionar todos los registros de la tabla Pieces_of_Luggage
SELECT * FROM Pieces_of_Luggage;
GO