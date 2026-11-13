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

