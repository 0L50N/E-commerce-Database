--Table "Customers": containing customers' personal data such as name, surname, e-mail and delivery address and customer ID.
--Table "Products": containing product data such as ID, name, price
--Table "Orders": containing data on orders placed, such as order number, order date, customer details and order details (products, quantity, price).
--Table "Returns": containing data on product returns, such as return number, return date, customer details and return details (products, quantity, price).
--Table "Employees": containing data on the shop's employees, such as name, ID and telephone number.

--Database will allow to ensure the operation of the business, inventory and handling of online orders.


--Require a valid email address when registering a customer-a restriction to check that the email address provided is correct using a regular expression or script.

email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[A-Z|a-z]{2,}$')

--Requires valid product data - e.g. price must be greater than 0 - a constraint can be set to check if price is a positive number.

price DECIMAL(10, 2) NOT NULL CHECK (price > 0)

--Require uniqueness for certain columns, such as ID number or email address - this constraint will ensure that no two entries have the same ID number or email address.

email VARCHAR(255) UNIQUE NOT NULL

--Requirements for certain columns - the NOT NULL restriction will ensure that certain columns must be populated when entering or updating data.

customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,

--Perspective showing a list of orders containing customer and product details:

CREATE VIEW OrderDetails AS SELECT 
Orders.order_id, Customers.first_name, Customers.last_name, Products.name, Orders.quantity 
FROM Orders
JOIN Customers ON Orders.customer_id = Customers.customer_id JOIN Products ON Orders.product_id = Products.product_id;

--Perspective showing a list of returns containing details about the order, product and customer:

CREATE VIEW ReturnDetails AS 
SELECT 
    Returns.return_id,
    Orders.order_id,
    Customers.first_name,
    Customers.last_name,
    Products.name,
    Returns.quantity
FROM Returns
JOIN Orders ON Returns.order_id = Orders.order_id
JOIN Customers ON Orders.customer_id = Customers.customer_id
JOIN Products ON Returns.product_id = Products.product_id;


--Query to add a new customer to the Customers table:

INSERT INTO Clients (first_name, last_name, email, address)
VALUES ('Aleksander', 'Kuciński', 'akucinski@edu.cdv.pl', 'ul. Karpia 25A/87, Poznań');

--Query that updates the price of a product with ID 1:

UPDATE Products
SET price = 9.99
WHERE product_id = 1;

--Query to delete an order with ID 1:

DELETE FROM Orders
WHERE order_id = 1;

--Transaction adding a new customer and order:

BEGIN;

INSERT INTO Customers (customer_id, first_name, last_name, email, address) 
VALUES (420, 'Alexandra', 'Drajkowska', 'od98@email.com', 'Wapienna 9/15');

INSERT INTO Orders (order_id, customer_id, product_id, quantity) 
VALUES (157, 420, 735, 3);

COMMIT;

--Cursor to retrieve a list of orders for each customer and display their details:

DECLARE order_cursor CURSOR FOR 
    SELECT customer_id, order_id, product_id, quantity FROM Orders;

DECLARE @customer_id INT, @order_id INT, @product_id INT, @quantity INT;

OPEN order_cursor;
FETCH NEXT FROM order_cursor INTO @customer_id, @order_id, @product_id, @quantity;

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT Customers.first_name, Customers.last_name, Products.name, Orders.quantity
    FROM Customers
    JOIN Orders ON Customers.customer_id = Orders.customer_id
    JOIN Products ON Orders.product_id = Products.product_id
    WHERE Orders.customer_id = @customer_id;

    FETCH NEXT FROM order_cursor INTO @customer_id, @order_id, @product_id, @quantity;

END

CLOSE order_cursor;
DEALLOCATE order_cursor;
--Application of functions AND triggers:

--Function to calculate the total order amount for a given customer:

CREATE FUNCTION order_total ( @customer_id INT )
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @total DECIMAL(10, 2);
    SET @total = 0;
    
    SELECT @total = SUM(Products.price * Orders.quantity)
    FROM Orders
    JOIN Products ON Orders.product_id = Products.product_id
    WHERE Orders.customer_id = @customer_id;
    RETURN @total;
END;

SELECT order_total(1) AS total_order;


--Function to calculate the percentage discount for a product:

CREATE FUNCTION calculate_discount (@product_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @discount INT;
    SET @discount = 0;

    SELECT @discount = discount
    FROM PRODUCTS
    WHERE product_id = @product_id;

    RETURN @discount;
END;

SELECT calculate_discount(1) AS discount;

--trigger to update product quantity after order or return:

CREATE TRIGGER update_product_quantity
AFTER INSERT, UPDATE ON Orders, Returns
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE order_id IS NOT NULL) THEN
        UPDATE Products
        SET quantity = quantity - inserted.quantity
        WHERE product_id = inserted.product_id;
    ELSE
        UPDATE Products
        SET quantity = quantity + inserted.quantity
        WHERE product_id = inserted.product_id;
    END IF;
END;

--trigger restricting the deletion of employees from the database:

CREATE TRIGGER restriction_employee_deletion
INSTEAD OF DELETE ON Employees
FOR EACH ROW
BEGIN
    RAISERROR ('Unable to delete employee', 16, 1);
    ROLLBACK TRANSACTION;
END;

--Other useful components:

--Index on the 'email' column in the 'Customers' table:

CREATE INDEX email_index ON Customers (email);

--Procedure to retrieve the order list for a given customer:

CREATE PROCEDURE get_customer_orders (@customer_id INTEGER)
AS
BEGIN
SELECT 
order_id, 
product_id, 
quantity 
FROM 
Orders
WHERE 
customer_id = @customer_id;
END;

--Access control:

CREATE ROLE readonly;
GRANT SELECT ON customers TO readonly;