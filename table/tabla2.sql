USE MASTER;
BEGIN TRY
    -- Verificar si la base de datos existe
    IF DB_ID('AirlineDB') IS NOT NULL
    BEGIN
        -- Establecer la base de datos en modo de usuario único y cerrar todas las conexiones activas
        ALTER DATABASE AirlineDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        PRINT 'Conexiones activas cerradas.';

        -- Intentar eliminar la base de datos
        DROP DATABASE AirlineDB;
        PRINT 'Base de datos AirlineDB eliminada.';
    END
END TRY
BEGIN CATCH
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

-- Creación de la tabla Country
IF OBJECT_ID('Country', 'U') IS NULL 
BEGIN
  CREATE TABLE Country (
    IdCountry INT PRIMARY KEY,  
    NameC NVARCHAR(255) NOT NULL UNIQUE  
  );
  PRINT 'Tabla Country creada.';
END
GO

-- Creación de la tabla City
IF OBJECT_ID('City', 'U') IS NULL 
BEGIN
  CREATE TABLE City (
    IdCity INT PRIMARY KEY,  
    Name NVARCHAR(255) NOT NULL,  
    IdCountry INT NOT NULL,  
    FOREIGN KEY (IdCountry) REFERENCES Country(IdCountry) ON DELETE CASCADE,
    CONSTRAINT UQ_City_Name UNIQUE (Name)  -- Asegura que el nombre de la ciudad sea único
  );
  PRINT 'Tabla City creada.';
END
GO

-- Creación de la tabla Airport
IF OBJECT_ID('Airport', 'U') IS NULL 
BEGIN
  CREATE TABLE Airport (
        IdAirport INT PRIMARY KEY,  
        Name NVARCHAR(255) NOT NULL UNIQUE,  
        IdCity INT NULL,  
        Latitude DECIMAL(9, 6) NOT NULL,  
        Longitude DECIMAL(9, 6) NOT NULL,  
        Description NVARCHAR(255) NULL,  
        FOREIGN KEY (IdCity) REFERENCES City(IdCity) ON DELETE SET NULL,
        CONSTRAINT UQ_Airport_Location UNIQUE (Latitude, Longitude)  -- Coordenadas únicas
  );
  PRINT 'Tabla Airport creada.';
END
GO

-- Creación de la tabla Plane_Model
IF OBJECT_ID('Plane_Model', 'U') IS NULL 
BEGIN
  CREATE TABLE Plane_Model (
    Id NVARCHAR(50) PRIMARY KEY,  
    Description NVARCHAR(255) NULL,  
    Graphic NVARCHAR(255) NULL
  );
  PRINT 'Tabla Plane_Model creada.';
END
GO

-- Creación de la tabla Airplane
IF OBJECT_ID('Airplane', 'U') IS NULL 
BEGIN
  CREATE TABLE Airplane (
    RegistrationNumber NVARCHAR(50) PRIMARY KEY,  
    BeginOfOperation DATE NOT NULL,  
    Status NVARCHAR(50) NULL DEFAULT 'Active',  -- Estado predeterminado como 'Activo'
    PlaneModel_Id NVARCHAR(50) NULL,  
    FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE SET NULL  
  );
  PRINT 'Tabla Airplane creada.';
END
GO

-- Creación de la tabla Customer
IF OBJECT_ID('Customer', 'U') IS NULL 
BEGIN
  CREATE TABLE Customer (
    IdCustomer INT PRIMARY KEY,  
    Name NVARCHAR(255) NOT NULL,  
    DateOfBirth DATE CHECK (DateOfBirth < GETDATE()),  -- Fecha de nacimiento válida (en el pasado)
    Email NVARCHAR(255) UNIQUE NOT NULL,  -- Correo único
    PhoneNumber NVARCHAR(15) NULL
  );
  PRINT 'Tabla Customer creada.';
END
GO

-- Creación de la tabla Frequent_Flyer_Card
IF OBJECT_ID('Frequent_Flyer_Card', 'U') IS NULL 
BEGIN
  CREATE TABLE Frequent_Flyer_Card (
    FCC_Number NVARCHAR(50) PRIMARY KEY,  
    Miles INT CHECK (Miles >= 0),  -- Asegurar que las millas no sean negativas
    IdCustomer INT NOT NULL,  
    FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE  
  );
  PRINT 'Tabla Frequent_Flyer_Card creada.';
END
GO

-- Creación de la tabla Flight_Number
IF OBJECT_ID('Flight_Number', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight_Number (
    IdFlightNumber INT PRIMARY KEY,  
    DepartureTime DATETIME NOT NULL,  
    Description NVARCHAR(255) NULL,  
    Type NVARCHAR(50) NULL,  
    Airline NVARCHAR(50) NOT NULL,  -- Asegurar que siempre haya una aerolínea asignada
    Start_Airport NVARCHAR(255) NOT NULL,  
    Goal_Airport NVARCHAR(255) NOT NULL,  
    PlaneModel_Id NVARCHAR(50) NULL,  
    FOREIGN KEY (Start_Airport) REFERENCES Airport(Name) ON DELETE NO ACTION,
    FOREIGN KEY (Goal_Airport) REFERENCES Airport(Name) ON DELETE NO ACTION,
    FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE SET NULL  
  );
  PRINT 'Tabla Flight_Number creada.';
END
GO

-- Creación de la tabla Flight_Category
IF OBJECT_ID('Flight_Category', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight_Category (
    IdFlightCategory INT PRIMARY KEY,  
    Name NVARCHAR(255) NOT NULL UNIQUE,  
    Description NVARCHAR(255) NULL  
  );
  PRINT 'Tabla Flight_Category creada.';
END
GO

-- Creación de la tabla Flight
IF OBJECT_ID('Flight', 'U') IS NULL 
BEGIN
  CREATE TABLE Flight (
    IdFlight INT PRIMARY KEY,  
    BoardingTime DATETIME NOT NULL,  
    FlightDate DATE NOT NULL,  
    Gate NVARCHAR(50) NULL,  
    CheckInCounter NVARCHAR(50) NULL,  
    IdFlightNumber INT NOT NULL,  
    Description NVARCHAR(255) NULL,  
    IdFlightCategory INT NULL,  
    FOREIGN KEY (IdFlightNumber) REFERENCES Flight_Number(IdFlightNumber) ON DELETE CASCADE,
    FOREIGN KEY (IdFlightCategory) REFERENCES Flight_Category(IdFlightCategory) ON DELETE SET NULL  
  );
  PRINT 'Tabla Flight creada.';
END
GO

-- Creación de la tabla Seat
IF OBJECT_ID('Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Seat (
    IdSeat INT PRIMARY KEY,  
    Size NVARCHAR(50) NOT NULL,  
    Number NVARCHAR(50) NOT NULL,  
    Location NVARCHAR(255) NULL,  
    PlaneModel_Id NVARCHAR(50) NOT NULL,  
    FOREIGN KEY (PlaneModel_Id) REFERENCES Plane_Model(Id) ON DELETE CASCADE  
  );
  PRINT 'Tabla Seat creada.';
END
GO

-- Creación de la tabla Available_Seat
IF OBJECT_ID('Available_Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Available_Seat (
    IdAvailableSeat INT PRIMARY KEY,  
    IdFlight INT NOT NULL,  
    IdSeat INT NOT NULL,  
    FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE CASCADE,
    FOREIGN KEY (IdSeat) REFERENCES Seat(IdSeat) ON DELETE CASCADE
  );
  PRINT 'Tabla Available_Seat creada.';
END
GO

-- Creación de la tabla Ticket
IF OBJECT_ID('Ticket', 'U') IS NULL 
BEGIN
  CREATE TABLE Ticket (
    TicketingCode NVARCHAR(50) PRIMARY KEY,  
    Number NVARCHAR(50) NOT NULL UNIQUE,  -- Asegurar que el número de ticket sea único
    IdCustomer INT NOT NULL,  
    FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE  
  );
  PRINT 'Tabla Ticket creada.';
END
GO

-- Creación de la tabla Coupon
IF OBJECT_ID('Coupon', 'U') IS NULL 
BEGIN
  CREATE TABLE Coupon (
    IdCoupon INT PRIMARY KEY,  
    TicketingCode NVARCHAR(50) NOT NULL,  
    Number NVARCHAR(50) NOT NULL,  
    Standby BIT NOT NULL DEFAULT 0,  -- Predeterminado a "0" (no standby)
    MealCode NVARCHAR(50) NULL,  
    IdFlight INT NOT NULL,  
    IdAvailableSeat INT NOT NULL,  
    FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE,  
    FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE NO ACTION,  
    FOREIGN KEY (IdAvailableSeat) REFERENCES Available_Seat(IdAvailableSeat) ON DELETE NO ACTION  
  );
  PRINT 'Tabla Coupon creada.';
END
GO

-- Creación de la tabla Pieces_of_Luggage
IF OBJECT_ID('Pieces_of_Luggage', 'U') IS NULL 
BEGIN
  CREATE TABLE Pieces_of_Luggage (
    IdLuggage INT PRIMARY KEY,  
    Number NVARCHAR(50) NOT NULL CHECK (LEN(Number) <= 50),  
    Weight DECIMAL(5, 2) NOT NULL CHECK (Weight >= 0),  -- Peso no negativo
    IdCoupon INT NOT NULL,  
    FOREIGN KEY (IdCoupon) REFERENCES Coupon(IdCoupon) ON DELETE CASCADE  
  );
  PRINT 'Tabla Pieces_of_Luggage creada.';
END
GO

-- Creación de la tabla Payment_Method
IF OBJECT_ID('Payment_Method', 'U') IS NULL 
BEGIN
  CREATE TABLE Payment_Method (
    IdPaymentMethod INT PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255) NULL
  );
  PRINT 'Tabla Payment_Method creada.';
END
GO

-- Creación de la tabla Payment
IF OBJECT_ID('Payment', 'U') IS NULL 
BEGIN
  CREATE TABLE Payment (
    IdPayment INT PRIMARY KEY,
    Amount DECIMAL(10, 2) NOT NULL CHECK (Amount > 0),  -- El monto no puede ser negativo
    PaymentDate DATE NOT NULL,
    IdPaymentMethod INT NOT NULL,
    TicketingCode NVARCHAR(50) NOT NULL,
    FOREIGN KEY (IdPaymentMethod) REFERENCES Payment_Method(IdPaymentMethod) ON DELETE NO ACTION,
    FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE
  );
  PRINT 'Tabla Payment creada.';
END
GO

-- Creación de la tabla Sales_Invoice
IF OBJECT_ID('Sales_Invoice', 'U') IS NULL 
BEGIN
  CREATE TABLE Sales_Invoice (
    IdSalesInvoice INT PRIMARY KEY,
    TicketingCode NVARCHAR(50) NOT NULL,
    SaleDate DATE NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL CHECK (TotalAmount > 0),  -- El total no puede ser negativo
    FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE
  );
  PRINT 'Tabla Sales_Invoice creada.';
END
GO

-- Creación de la tabla Reservation
IF OBJECT_ID('Reservation', 'U') IS NULL 
BEGIN
  CREATE TABLE Reservation (
    ReservationDate DATE NOT NULL,
    PaymentDueDate DATE NOT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',  -- Predeterminado a "Pendiente"
    TotalPrice DECIMAL(10, 2) NOT NULL CHECK (TotalPrice > 0),  -- Precio no negativo
    TicketingCode NVARCHAR(50) NOT NULL,
    PRIMARY KEY (TicketingCode),
    FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE
  );
  PRINT 'Tabla Reservation creada.';
END
GO

-- Creación de la tabla Ticket_Charge
IF OBJECT_ID('Ticket_Charge', 'U') IS NULL 
BEGIN
  CREATE TABLE Ticket_Charge (
    TicketingCode NVARCHAR(50) NOT NULL,
    OriginalFlightDate DATE NOT NULL,
    NewFlightDate DATE NOT NULL,
    ChargeDate DATE NOT NULL,
    PenaltyAmount DECIMAL(10, 2) NOT NULL CHECK (PenaltyAmount >= 0),  -- Penalización no negativa
    Reason NVARCHAR(200) NULL,
    PRIMARY KEY (TicketingCode, OriginalFlightDate),
    FOREIGN KEY (TicketingCode) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE
  );
  PRINT 'Tabla Ticket_Charge creada.';
END
GO

-- Creación de la tabla Document con relación a Customer
IF OBJECT_ID('Document', 'U') IS NULL 
BEGIN
  CREATE TABLE Document (
    IdDocument INT PRIMARY KEY,
    Description NVARCHAR(255) NULL,
    IdCustomer INT NOT NULL,  
    FOREIGN KEY (IdCustomer) REFERENCES Customer(IdCustomer) ON DELETE CASCADE  
  );
  PRINT 'Tabla Document creada.';
END
GO

-- Creación de la tabla Reserved_Seat
IF OBJECT_ID('Reserved_Seat', 'U') IS NULL 
BEGIN
  CREATE TABLE Reserved_Seat (
    IdReservedSeat INT PRIMARY KEY,  
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),  -- Precio positivo
    TicketingCode NVARCHAR(50) NOT NULL,  
    FOREIGN KEY (TicketingCode) REFERENCES Reservation(TicketingCode) ON DELETE CASCADE  
  );
  PRINT 'Tabla Reserved_Seat creada.';
END
GO

-- Creación de la tabla Checking
IF OBJECT_ID('Checking', 'U') IS NULL 
BEGIN
  CREATE TABLE Checking (
    IdChecking INT PRIMARY KEY,  
    Seat_Number NVARCHAR(50) NOT NULL,  
    Baggage_Count INT NOT NULL CHECK (Baggage_Count >= 0),  
    CheckIn_Time DATETIME NOT NULL,  
    Boarding_Time DATETIME NOT NULL,  
    Status NVARCHAR(50) NULL DEFAULT 'Pending',  
    IdTicket NVARCHAR(50) NOT NULL,  
    IdFlight INT NOT NULL,  
    FOREIGN KEY (IdTicket) REFERENCES Ticket(TicketingCode) ON DELETE CASCADE,  
    FOREIGN KEY (IdFlight) REFERENCES Flight(IdFlight) ON DELETE CASCADE
  );
  PRINT 'Tabla Checking creada.';
END
GO

---------------------- Llamadas SELECT -------------------
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

-- Seleccionar todos los registros de la tabla Frequent_Flyer_Card;
SELECT * FROM Frequent_Flyer_Card;

-- Seleccionar todos los registros de la tabla Flight_Number;
SELECT * FROM Flight_Number;

-- Seleccionar todos los registros de la tabla Flight;

-- Seleccionar todos los registros de la tabla Seat;
SELECT * FROM Seat;

-- Seleccionar todos los registros de la tabla Available_Seat;
SELECT * FROM Available_Seat;

-- Seleccionar todos los registros de la tabla Ticket;
SELECT * FROM Ticket;

-- Seleccionar todos los registros de la tabla Coupon;
SELECT * FROM Coupon;

-- Seleccionar todos los registros de la tabla Pieces_of_Luggage;
SELECT * FROM Pieces_of_Luggage;

-- Seleccionar todos los registros de la tabla Payment_Method;
SELECT * FROM Payment_Method;

-- Seleccionar todos los registros de la tabla Payment;

-- Seleccionar todos los registros de la tabla Sales_Invoice;
SELECT * FROM Sales_Invoice;

-- Seleccionar todos los registros de la tabla Reservation;
SELECT * FROM Reservation;

-- Seleccionar todos los registros de la tabla Ticket_Charge;
SELECT * FROM Ticket_Charge;

-- Seleccionar todos los registros de la tabla Document;
SELECT * FROM Document;

-- Seleccionar todos los registros de la tabla Reserved_Seat;
SELECT * FROM Reserved_Seat;

-- Seleccionar todos los registros de la tabla Checking;
SELECT * FROM Checking;
GO
