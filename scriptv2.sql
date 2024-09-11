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

-- Creaci�n del �ndice en IdCountry para mejorar consultas
CREATE INDEX IDX_City_IdCountry ON City(IdCountry);
GO

-- Creaci�n de la tabla Airport
IF OBJECT_ID('Airport', 'U') IS NULL 
BEGIN
  CREATE TABLE Airport (
        Name NVARCHAR(255) PRIMARY KEY,  -- Clave primaria para el nombre del aeropuerto, debe ser �nico
        IdCity INT NULL,  -- Referencia a la ciudad, permite valores nulos
        Latitude DECIMAL(9, 6) NOT NULL,  -- Latitud con precisi�n, no nula
        Longitude DECIMAL(9, 6) NOT NULL,  -- Longitud con precisi�n, no nula
        Description NVARCHAR(255) NULL,  -- Descripci�n opcional
        FOREIGN KEY (IdCity) REFERENCES City(IdCity) ON DELETE SET NULL  -- Regla de integridad: Si la ciudad es eliminada, se establece el campo en NULL
  );
  PRINT 'Tabla Airport creada.';
END
GO

-- Creaci�n del �ndice en IdCity para optimizar consultas
CREATE INDEX IDX_Airport_IdCity ON Airport(IdCity);
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

-- Creaci�n del �ndice en PlaneModel_Id
CREATE INDEX IDX_Airplane_PlaneModel_Id ON Airplane(PlaneModel_Id);
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

-- Creaci�n del �ndice en IdCustomer para mejorar consultas
CREATE INDEX IDX_Frequent_Flyer_Card_IdCustomer ON Frequent_Flyer_Card(IdCustomer);
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

-- Creaci�n del �ndice en Start_Airport, Goal_Airport y PlaneModel_Id
CREATE INDEX IDX_Flight_Number_Start_Airport ON Flight_Number(Start_Airport);
CREATE INDEX IDX_Flight_Number_Goal_Airport ON Flight_Number(Goal_Airport);
CREATE INDEX IDX_Flight_Number_PlaneModel_Id ON Flight_Number(PlaneModel_Id);
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

-- Creaci�n del �ndice en IdFlightNumber
CREATE INDEX IDX_Flight_IdFlightNumber ON Flight(IdFlightNumber);
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

-- Creaci�n del �ndice en PlaneModel_Id para mejorar rendimiento en b�squedas
CREATE INDEX IDX_Seat_PlaneModel_Id ON Seat(PlaneModel_Id);
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

-- Creaci�n del �ndice en IdFlight y IdSeat
CREATE INDEX IDX_Available_Seat_IdFlight ON Available_Seat(IdFlight);
CREATE INDEX IDX_Available_Seat_IdSeat ON Available_Seat(IdSeat);
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

-- Creaci�n del �ndice en IdCustomer
CREATE INDEX IDX_Ticket_IdCustomer ON Ticket(IdCustomer);
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

-- Creaci�n del �ndice en TicketingCode, IdFlight y IdAvailableSeat
CREATE INDEX IDX_Coupon_TicketingCode ON Coupon(TicketingCode);
CREATE INDEX IDX_Coupon_IdFlight ON Coupon(IdFlight);
CREATE INDEX IDX_Coupon_IdAvailableSeat ON Coupon(IdAvailableSeat);
GO

-- Creaci�n de la tabla Pieces_of_Luggage
IF OBJECT_ID('Pieces_of_Luggage', 'U') IS NULL 
BEGIN
  CREATE TABLE Pieces_of_Luggage (
    IdLuggage INT PRIMARY KEY,  -- Clave primaria, identificador �nico del equipaje
    Number NVARCHAR(50) NOT NULL,  -- N�mero del equipaje, obligatorio
    Weight DECIMAL(5, 2) NOT NULL,  -- Peso del equipaje, obligatorio
    IdCoupon INT NOT NULL,  -- Referencia al cup�n, obligatorio
    FOREIGN KEY (IdCoupon) REFERENCES Coupon(IdCoupon) ON DELETE CASCADE  -- Regla de integridad: Si se elimina el cup�n, se elimina el equipaje asociado
  );
  PRINT 'Tabla Pieces_of_Luggage creada.';
END
GO

-- Creaci�n del �ndice en IdCoupon para mejorar consultas
CREATE INDEX IDX_Pieces_of_Luggage_IdCoupon ON Pieces_of_Luggage(IdCoupon);
GO

-----------------------POBALCION--------------
create procedure  poblar
as
begin
-- Poblaci�n de la tabla Country
INSERT INTO Country (IdCountry, NameC) VALUES (1, 'USA');
INSERT INTO Country (IdCountry, NameC) VALUES (2, 'Canada');
INSERT INTO Country (IdCountry, NameC) VALUES (3, 'Mexico');

-- Poblaci�n de la tabla City
INSERT INTO City (IdCity, Name, IdCountry) VALUES (1, 'New York', 1);
INSERT INTO City (IdCity, Name, IdCountry) VALUES (2, 'Toronto', 2);
INSERT INTO City (IdCity, Name, IdCountry) VALUES (3, 'Mexico City', 3);
INSERT INTO City (IdCity, Name, IdCountry) VALUES (4, 'Los Angeles', 1);
INSERT INTO City (IdCity, Name, IdCountry) VALUES (5, 'Vancouver', 2);

-- Poblaci�n de la tabla Airport
INSERT INTO Airport (Name, IdCity, Latitude, Longitude, Description) 
VALUES 
('JFK International', 1, 40.641311, -73.778139, 'John F. Kennedy International Airport in New York City, USA'),
('Toronto Pearson', 2, 43.677717, -79.624819, 'Toronto Pearson International Airport in Toronto, Canada'),
('Benito Ju�rez', 3, 19.436303, -99.072096, 'Benito Ju�rez International Airport in Mexico City, Mexico'),
('LAX', 4, 33.941589, -118.40853, 'Los Angeles International Airport in Los Angeles, USA'),
('Vancouver International', 5, 49.195069, -123.179611, 'Vancouver International Airport in Vancouver, Canada');

-- Poblaci�n de la tabla Plane_Model
INSERT INTO Plane_Model (Id, Description, Graphic) VALUES ('B737', 'Boeing 737', 'B737.jpg');
INSERT INTO Plane_Model (Id, Description, Graphic) VALUES ('A320', 'Airbus A320', 'A320.jpg');
INSERT INTO Plane_Model (Id, Description, Graphic) VALUES ('B777', 'Boeing 777', 'B777.jpg');

-- Poblaci�n de la tabla Airplane
INSERT INTO Airplane (RegistrationNumber, BeginOfOperation, Status, PlaneModel_Id) VALUES ('N12345', '2020-01-15', 'Active', 'B737');
INSERT INTO Airplane (RegistrationNumber, BeginOfOperation, Status, PlaneModel_Id) VALUES ('N67890', '2019-05-20', 'Active', 'A320');
INSERT INTO Airplane (RegistrationNumber, BeginOfOperation, Status, PlaneModel_Id) VALUES ('N54321', '2021-07-30', 'Maintenance', 'B777');

-- Poblaci�n de la tabla Customer
INSERT INTO Customer (IdCustomer, Name, DateOfBirth) VALUES (1, 'John Doe', '1980-04-23');
INSERT INTO Customer (IdCustomer, Name, DateOfBirth) VALUES (2, 'Jane Smith', '1992-08-14');
INSERT INTO Customer (IdCustomer, Name, DateOfBirth) VALUES (3, 'Carlos Rivera', '1975-12-01');

-- Poblaci�n de la tabla Frequent_Flyer_Card
INSERT INTO Frequent_Flyer_Card (FCC_Number, Miles, IdCustomer) VALUES ('FF12345', 15000, 1);
INSERT INTO Frequent_Flyer_Card (FCC_Number, Miles, IdCustomer) VALUES ('FF67890', 23000, 2);
INSERT INTO Frequent_Flyer_Card (FCC_Number, Miles, IdCustomer) VALUES ('FF54321', 12000, 3);

-- Poblaci�n de la tabla Flight_Number
INSERT INTO Flight_Number (IdFlightNumber, DepartureTime, Description, Type, Airline, Start_Airport, Goal_Airport, PlaneModel_Id) 
VALUES (1, '2023-09-01 08:00:00', 'Flight to Toronto', 'Commercial', 'Delta', 'JFK International', 'Toronto Pearson', 'B737');
INSERT INTO Flight_Number (IdFlightNumber, DepartureTime, Description, Type, Airline, Start_Airport, Goal_Airport, PlaneModel_Id) 
VALUES (2, '2023-09-02 09:30:00', 'Flight to Mexico City', 'Commercial', 'Air Canada', 'Toronto Pearson', 'Benito Ju�rez', 'A320');
INSERT INTO Flight_Number (IdFlightNumber, DepartureTime, Description, Type, Airline, Start_Airport, Goal_Airport, PlaneModel_Id) 
VALUES (3, '2023-09-03 07:00:00', 'Flight to Los Angeles', 'Commercial', 'American Airlines', 'LAX', 'Vancouver International', 'B777');

-- Poblaci�n de la tabla Flight
INSERT INTO Flight (IdFlight, BoardingTime, FlightDate, Gate, CheckInCounter, IdFlightNumber) 
VALUES (1, '2023-09-01 07:30:00', '2023-09-01', 'A1', 'C5', 1);
INSERT INTO Flight (IdFlight, BoardingTime, FlightDate, Gate, CheckInCounter, IdFlightNumber) 
VALUES (2, '2023-09-02 09:00:00', '2023-09-02', 'B2', 'D3', 2);
INSERT INTO Flight (IdFlight, BoardingTime, FlightDate, Gate, CheckInCounter, IdFlightNumber) 
VALUES (3, '2023-09-03 06:30:00', '2023-09-03', 'C1', 'A2', 3);


-- Poblaci�n de la tabla Seat
INSERT INTO Seat (IdSeat, Size, Number, Location, PlaneModel_Id) 
VALUES (1, 'Large', '1A', 'Front', 'B737');
INSERT INTO Seat (IdSeat, Size, Number, Location, PlaneModel_Id) 
VALUES (2, 'Medium', '2B', 'Middle', 'A320');
INSERT INTO Seat (IdSeat, Size, Number, Location, PlaneModel_Id) 
VALUES (3, 'Small', '3C', 'Back', 'B777');

-- Poblaci�n de la tabla Available_Seat
INSERT INTO Available_Seat (IdAvailableSeat, IdFlight, IdSeat) 
VALUES (1, 1, 1);
INSERT INTO Available_Seat (IdAvailableSeat, IdFlight, IdSeat) 
VALUES (2, 2, 2);
INSERT INTO Available_Seat (IdAvailableSeat, IdFlight, IdSeat) 
VALUES (3, 3, 3);

-- Poblaci�n de la tabla Ticket
INSERT INTO Ticket (TicketingCode, Number, IdCustomer) 
VALUES ('TCKT001', '0001', 1);
INSERT INTO Ticket (TicketingCode, Number, IdCustomer) 
VALUES ('TCKT002', '0002', 2);
INSERT INTO Ticket (TicketingCode, Number, IdCustomer) 
VALUES ('TCKT003', '0003', 3);

-- Poblaci�n de la tabla Coupon
INSERT INTO Coupon (IdCoupon, TicketingCode, Number, Standby, MealCode, IdFlight, IdAvailableSeat) 
VALUES (1, 'TCKT001', 'C001', 0, 'Veg', 1, 1);
INSERT INTO Coupon (IdCoupon, TicketingCode, Number, Standby, MealCode, IdFlight, IdAvailableSeat) 
VALUES (2, 'TCKT002', 'C002', 0, 'Non-Veg', 2, 2);
INSERT INTO Coupon (IdCoupon, TicketingCode, Number, Standby, MealCode, IdFlight, IdAvailableSeat) 
VALUES (3, 'TCKT003', 'C003', 1, 'Veg', 3, 3);

-- Poblaci�n de la tabla Pieces_of_Luggage
INSERT INTO Pieces_of_Luggage (IdLuggage, Number, Weight, IdCoupon) 
VALUES (1, 'L001', 23.5, 1);
INSERT INTO Pieces_of_Luggage (IdLuggage, Number, Weight, IdCoupon) 
VALUES (2, 'L002', 25.0, 2);
INSERT INTO Pieces_of_Luggage (IdLuggage, Number, Weight, IdCoupon) 
VALUES (3, 'L003', 22.3, 3);

end
GO
EXECUTE poblar 

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