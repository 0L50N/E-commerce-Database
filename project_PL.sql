
--Tabela "Klienci": zawierająca dane osobowe klientów, takie jak imię, nazwisko, adres e-mail i adres dostawy oraz ID klienta.
--Tabela "Produkty": zawierająca dane dotyczące produktów, takie jak ID, nazwa, cena
--Tabela "Zamówienia": zawierająca dane dotyczące złożonych zamówień, takie jak numer zamówienia, data zamówienia, dane klienta i szczegóły zamówienia (produkty, ilość, cena).
--Tabela "Zwroty": zawierająca dane dotyczące zwrotów produktów, takie jak numer zwrotu, data zwrotu, dane klienta i szczegóły zwrotu (produkty, ilość, cena).
--Tabela "Pracownicy": zawierająca dane dotyczące pracowników sklepu, takie jak imię, nazwisko, ID i numer telefonu.

--Baza danych pozwoli na zapewnienie funkcjonowania przedsiębiorstwa, inwentaryzację oraz obsługę zamówień internetowych.


--Wymóg podawania prawidłowego adresu e-mail przy rejestracji klienta – ograniczenie dla sprawdzenia, czy podany adres e-mail jest poprawny za pomocą wyrażenia regularnego lub skryptu.

email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')

--Wymóg podawania prawidłowych danych produktu - np. cena musi być większa niż 0 - można ustawić ograniczenie, aby sprawdzić, czy cena jest liczbą dodatnią.

price DECIMAL(10, 2) NOT NULL CHECK (price > 0)

--Wymóg unikalności dla pewnych kolumn, takie jak numer identyfikacyjny lub adres e-mail - ograniczenie to zapewni, że nie będzie dwóch wpisów z takim samym numerem identyfikacyjnym lub adresem e-mail.

email VARCHAR(255) UNIQUE NOT NULL

--Wymóg podawania danych dla pewnych kolumn - ograniczenie NOT NULL zapewni, że pewne kolumny muszą być wypełnione podczas wprowadzania lub aktualizowania danych.

customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,

--Perspektywa pokazująca listę zamówień zawierających szczegóły o kliencie i produkcie:

CREATE VIEW OrderDetails AS SELECT 
Zamówienia.order_id, Klienci.first_name, Klienci.last_name, Produkty.name, Zamówienia.quantity 
FROM Zamówienia
JOIN Klienci ON Zamówienia.customer_id = Klienci.customer_id JOIN Produkty ON Zamówienia.product_id = Produkty.product_id;

--Perspektywa pokazująca listę zwrotów zawierających szczegóły o zamówieniu, produkcie i kliencie:

CREATE VIEW ReturnDetails AS 
SELECT 
    Zwroty.return_id,
    Zamówienia.order_id,
    Klienci.first_name,
    Klienci.last_name,
    Produkty.name,
    Zwroty.quantity
FROM Zwroty
JOIN Zamówienia ON Zwroty.order_id = Zamówienia.order_id
JOIN Klienci ON Zamówienia.customer_id = Klienci.customer_id
JOIN Produkty ON Zwroty.product_id = Produkty.product_id;

--Kwerenda dodająca nowego klienta do tabeli Klienci:

INSERT INTO Klienci (first_name, last_name, email, address)
VALUES ('Aleksander', 'Kuciński', ‘akucinski@edu.cdv.pl’, 'ul. Karpia 25A/87, Poznań');

--Kwerenda aktualizująca cenę produktu o ID 1:

UPDATE Produkty
SET price = 9.99
WHERE product_id = 1;

--Kwerenda usuwająca zamówienie o ID 1:

DELETE FROM Zamówienia
WHERE order_id = 1;

--Transakcja dodająca nowego klienta i zamówienie:

BEGIN;

INSERT INTO Klienci (customer_id, first_name, last_name, email, address) 
VALUES (420, 'Alexandra', 'Drajkowska', 'od98@email.com', 'Wapienna 9/15');

INSERT INTO Zamówienia (order_id, customer_id, product_id, quantity) 
VALUES (157, 420, 735, 3);

COMMIT;

--Kursor pobierający listę zamówień dla każdego klienta i wyświetlający ich szczegóły:

DECLARE order_kursor CURSOR FOR 
    SELECT customer_id, order_id, product_id, quantity FROM Zamówienia;

DECLARE @customer_id INT, @order_id INT, @product_id INT, @quantity INT;

OPEN order_cursor;
FETCH NEXT FROM order_cursor INTO @customer_id, @order_id, @product_id, @quantity;

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT Klienci.first_name, Klienci.last_name, Produkty.name, Zamówienia.quantity
    FROM Klienci
    JOIN Zamówienia ON Klienci.customer_id = Zamówienia.customer_id
    JOIN Produkty ON Zamówienia.product_id = Produkty.product_id
    WHERE Zamówienia.customer_id = @customer_id;

    FETCH NEXT FROM order_cursor INTO @customer_id, @order_id, @product_id, @quantity;

END

CLOSE order_kursor;
DEALLOCATE order_kursor;
--Zastosowanie funkcji I wyzwalaczy:

--Funkcja do obliczenia sumy kwoty zamówienia dla danego klienta:

CREATE FUNCTION order_total ( @customer_id INT )
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @total DECIMAL(10, 2);
    SET @total = 0;
    
    SELECT @total = SUM(Produkty.price * Zamówienia.quantity)
    FROM Zamówienia
    JOIN Produkty ON Zamówienia.product_id = Produkty.product_id
    WHERE Zamówienia.customer_id = @customer_id;
    RETURN @total;
END;

SELECT order_total(1) AS total_order;


--Funkcja do obliczenia procentowego rabatu dla danego produktu:

CREATE FUNCTION calculate_discount (@product_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @discount INT;
    SET @discount = 0;

    SELECT @discount = discount
    FROM Produkty
    WHERE product_id = @product_id;

    RETURN @discount;
END;

SELECT calculate_discount(1) AS discount;

--wyzwalacz do aktualizowania ilości produktu po dokonaniu zamówienia lub zwrotu:

CREATE TRIGGER update_product_quantity
AFTER INSERT, UPDATE ON Zamówienia, Zwroty
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE order_id IS NOT NULL) THEN
        UPDATE Produkty
        SET quantity = quantity - inserted.quantity
        WHERE product_id = inserted.product_id;
    ELSE
        UPDATE Produkty
        SET quantity = quantity + inserted.quantity
        WHERE product_id = inserted.product_id;
    END IF;
END;

--wyzwalacz ograniczający usuwanie pracowników z bazy danych:

CREATE TRIGGER restriction_employee_deletion
INSTEAD OF DELETE ON Pracownicy
FOR EACH ROW
BEGIN
    RAISERROR ('Nie można usunąć pracownika', 16, 1);
    ROLLBACK TRANSACTION;
END;

--Inne przydatne składniki:

--Indeks na kolumnie ‘email’ w tabeli ‘Klienci’:

CREATE INDEX email_index ON Klienci (email);

--Procedura do pobrania listy zamówień dla danego klienta:

CREATE PROCEDURE get_customer_orders (@customer_id INTEGER)
AS
BEGIN
SELECT 
order_id, 
product_id, 
quantity 
FROM 
Zamówienia
WHERE 
customer_id = @customer_id;
END;

--Kontrola dostępu:

CREATE ROLE readonly;
GRANT SELECT ON Klienci TO readonly;
