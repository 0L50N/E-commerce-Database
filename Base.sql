CREATE TABLE Klienci (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    address TEXT NOT NULL
);

CREATE TABLE Produkty (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    quantity INTEGER,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0)
);

CREATE TABLE Zamówienia (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Klienci (customer_id),
    FOREIGN KEY (product_id) REFERENCES Produkty (product_id)
);

CREATE TABLE Zwroty (
    return_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Zamówienia (order_id),
    FOREIGN KEY (product_id) REFERENCES Produkty (product_id)
);

CREATE TABLE Pracownicy (
    employee_id INTEGER PRIMARY KEY,
    first_name_e TEXT NOT NULL,
    last_name_e TEXT NOT NULL,
    phone_number TEXT NOT NULL
);
