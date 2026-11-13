-- Active: 1792410250481@@127.0.0.1@3306
DROP DATABASE IF EXISTS nordicrent_api; 

CREATE DATABASE nordicrent_api CHARACTER SET utf8mb4;

USE nordicrent_api;

 CREATE TABLE depots 
 (depot_id INT AUTO_INCREMENT PRIMARY KEY, 
 name VARCHAR(70) NOT NULL, 
 city VARCHAR(50) NOT NULL, 
 address VARCHAR(150) NOT NULL,
 -- Same name in different cities is allowed, and a city can have several depots.
 -- The same name twice in the same city is not, so customers and staff can tell the depots apart.
 UNIQUE KEY uq_depot_location (name, city)
);

CREATE TABLE categories 
(category_id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(40) UNIQUE NOT NULL, 
 description TEXT NOT NULL
 );


 CREATE TABLE equipment (
    equipment_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    depot_id INT NOT NULL,
    model_name VARCHAR(80) NOT NULL,
    daily_price DECIMAL(7,2) NOT NULL,
    purchase_date DATE NOT NULL,
    status ENUM ('available', 'rented', 'maintenance', 'retired') NOT NULL DEFAULT 'available',
    CONSTRAINT fk_equipment_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_equipment_depot FOREIGN KEY (depot_id)
        REFERENCES depots(depot_id) ON DELETE RESTRICT,
    CONSTRAINT chk_equipment_daily_price CHECK (daily_price >= 0)       
 );

CREATE TABLE customers (
    customer_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(80) UNIQUE,
    phone VARCHAR(20),
    deleted_at DATETIME, -- NULL = active customer, a date = anonymized
    CONSTRAINT chk_customer_personal_data 
    CHECK (deleted_at IS NOT NULL OR
    (first_name IS NOT NULL AND last_name IS NOT NULL AND email IS NOT NULL AND phone IS NOT NULL))
);

CREATE TABLE bookings (
    booking_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM ('confirmed', 'active', 'returned', 'cancelled') NOT NULL DEFAULT 'confirmed',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT chk_booking_duration CHECK (end_date > start_date)
);

CREATE TABLE booking_lines (
    booking_line_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    equipment_id INT NOT NULL,
    daily_price DECIMAL(7,2) NOT NULL,
    CONSTRAINT fk_booking_lines_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_booking_lines_equipment FOREIGN KEY (equipment_id)
        REFERENCES equipment(equipment_id) ON DELETE RESTRICT,
    UNIQUE KEY uq_booking_equipment(booking_id, equipment_id),
    CONSTRAINT chk_booking_lines_daily_price CHECK (daily_price >= 0) 
);

-- App user for the Express API, with least privilege (no DELETE, no CREATE/ALTER/DROP).
-- '12345' is a local development password only. Change it before any real installation.
-- The real password must never be in the code: it belongs in .env, which is not committed to git.


DROP USER IF EXISTS 'nordicrent_app_user'@'127.0.0.1';
CREATE USER IF NOT EXISTS 'nordicrent_app_user'@'127.0.0.1'
    IDENTIFIED BY '12345';

GRANT SELECT, INSERT, UPDATE ON nordicrent_api.equipment TO 'nordicrent_app_user'@'127.0.0.1';
GRANT SELECT ON nordicrent_api.categories TO 'nordicrent_app_user'@'127.0.0.1';
GRANT SELECT ON nordicrent_api.depots TO 'nordicrent_app_user'@'127.0.0.1';
GRANT SELECT, INSERT ON nordicrent_api.bookings TO 'nordicrent_app_user'@'127.0.0.1';
GRANT SELECT, INSERT ON nordicrent_api.booking_lines TO 'nordicrent_app_user'@'127.0.0.1';

SHOW GRANTS FOR 'nordicrent_app_user'@'127.0.0.1';
